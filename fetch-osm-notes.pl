#!/usr/bin/env perl

# Fetch all open OSM notes within a bounding box using the /api/0.6/notes/search
# endpoint, paginating via the "to" parameter until all notes are retrieved.
# Note: the API silently ignores "to" unless "from" is also present, so every
# request includes from=1970-01-01T00:00:00Z as a fixed lower bound.
#
# Usage: fetch-osm-notes.pl <min_lon,min_lat,max_lon,max_lat> [output_file]
#
# If output_file is omitted or "-", output is written to stdout.

use strict;
use warnings;
use HTTP::Tiny;
use JSON::PP qw(decode_json encode_json);

my $bbox        = shift // die "Usage: $0 <bbox> [output_file]\n";
my $output_file = shift // '-';

my $base_url     = 'https://api.openstreetmap.org/api/0.6/notes/search.json';
my $limit        = 1000;   # per-page fetch limit
my $max_features = 10_000; # overall cap for merged results (0 = no limit)

my $ua = HTTP::Tiny->new(
    timeout => 60,
    agent   => 'osm-survey-jobs-fetcher/1.0 (https://github.com/eserte/osm-survey-jobs)',
);

if ( !$ua->can_ssl ) {
    die "SSL support is not available (install IO::Socket::SSL or Net::SSL)\n";
}

my @all_features;
my $to;

while (1) {
    my %params = (
        bbox    => $bbox,
        limit   => $limit,
        closed  => 0,
        sort    => 'created_at',
        order   => 'newest',
        from    => '1970-01-01T00:00:00Z',  # required: "to" is ignored without "from"
    );
    $params{to} = $to if defined $to;

    my $query_string = join '&', map { "$_=$params{$_}" } sort keys %params;
    my $url = "$base_url?$query_string";

    warn "Fetching: $url\n";

    my $response = $ua->get($url);
    die "HTTP request failed ($response->{status} $response->{reason}): $url\n"
        unless $response->{success};

    my $data     = decode_json( $response->{content} );
    my @features = @{ $data->{features} };

    last unless @features;

    push @all_features, @features;

    last if $max_features && @all_features >= $max_features;

    last if @features < $limit;

    # Determine the created_at of the oldest note in this batch to use as the
    # upper bound ("to") for the next request.  The API requires "from" to be
    # present for "to" to take effect; "from" is always sent as the epoch.
    my $oldest_created_at = _get_created_at( $features[-1] );
    last unless defined $oldest_created_at;

    # Convert "YYYY-MM-DD HH:MM:SS UTC" to ISO 8601 "YYYY-MM-DDTHH:MM:SSZ" if needed
    if ( $oldest_created_at =~ / \d{2}:\d{2}:\d{2} UTC$/ ) {
        $oldest_created_at =~ s/ (\d{2}:\d{2}:\d{2}) UTC$/T${1}Z/;
    }
    elsif ( $oldest_created_at !~ /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/ ) {
        warn "Unexpected date format '$oldest_created_at'; stopping pagination\n";
        last;
    }

    # Guard against an infinite loop when all remaining notes share the same
    # created_at timestamp.
    last if defined $to && $to eq $oldest_created_at;

    $to = $oldest_created_at;
}

# Deduplicate by note id (boundary notes may appear in two consecutive batches)
my %seen;
my @unique_features = grep {
    defined $_->{properties} && defined $_->{properties}{id}
        && !$seen{ $_->{properties}{id} }++
} @all_features;

warn "Fetched " . scalar(@unique_features) . " unique open note(s) in bbox $bbox\n";

my $result = {
    type     => 'FeatureCollection',
    features => \@unique_features,
};

my $json = encode_json($result);

if ( $output_file eq '-' ) {
    print $json, "\n";
}
else {
    open my $fh, '>', $output_file or die "Can't open '$output_file': $!\n";
    print $fh $json, "\n";
    close $fh;
}

# ---------------------------------------------------------------------------
# Return the created_at date for a note feature.
sub _get_created_at {
    my ($feature) = @_;
    my $props = $feature->{properties};
    return $props->{date_created};
}
