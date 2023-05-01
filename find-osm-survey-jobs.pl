#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use JSON::PP qw(decode_json);

my $debug;
my $url_in_name;
GetOptions(
	   "debug"       => \$debug,
	   "url-in-name" => \$url_in_name,
	  )
    or die "usage?";

my $json_file = shift // die "Please specify notes json file";

my $json = do {
    open my $fh, $json_file or die "Can't open $json_file: $!";
    local $/;
    <$fh>;
};
my $data = decode_json $json;

my @jobs;
for my $feature (@{ $data->{features} }) {
    my $properties = $feature->{properties};
    my @comments = reverse @{ $properties->{comments} || [] };
    my $id = $properties->{id};
    for my $comment (@comments) {
	my $text = $comment->{text};
	if (
	    # example:
	    #   https://www.mapillary.com/app/?pKey=7108870792519085&lat=52.4323902&lng=13.298390899972&z=17
	    $text =~ m{(https?://(?:www\.)?mapillary\.com/app\S*)} ||
	    # example:
	    #   https://www.mapillary.com/map/im/5bLwxKicTPyqBa2uDUEPGi
	    $text =~ m{(https?://(?:www\.)?mapillary\.com/map/im/\S*)} ||
	    # example:
	    #   https://kartaview.org/details/5200649/244/track-info
	    $text =~ m{(https?://(?:www\.)?kartaview\.org/details\S*)}
	) {
	    # already handled
	    if ($debug) {
		warn "Note $id is already by URL $1\n";
	    }
	    last;
	}
	if ($text =~ m{(
			   mapillary
		       |   kartaview
		       |   gopro
		       |   \b360\b(?!\s*m\b)
		       )}xi) {
	    my $geometry = $feature->{geometry};
	    if ($geometry->{type} ne 'Point') {
		die "Unexpected error: geometry type is not Point, but '$geometry->{type}', cannot handle this...";
	    }
	    my @coords = join(",", @{ $geometry->{coordinates} });
	    my $url = "https://www.openstreetmap.org/note/$id";
	    push @jobs, {
		notes_id => $id,
		notes_url => $url,
		date => $comment->{date},
		text => $comment->{text},
		user => $comment->{user} // '<anonymous>',
		coords => \@coords,
	    };
	    last;
	}
    }
}

if (!@jobs) {
    warn "No jobs found!\n";
    exit 1;
}

@jobs = sort { $b->{date} cmp $a->{date} } @jobs;

my $ofh = \*STDOUT;
binmode $ofh, ':utf8';
print "#: encoding: utf-8\n";
print "#: map: polar\n";
print "#:\n";
for my $job (@jobs) {
    my $shortened_text = $job->{text};
    $shortened_text =~ s{^\s+}{}g;
    $shortened_text =~ s{\s+$}{}g;
    $shortened_text =~ s{\t}{ }g;
    $shortened_text =~ s{^(.*)(.|\n)*}{$1};
    if (length $shortened_text > 256) {
	$shortened_text = substr($shortened_text, 0, 256) . "...";
    }
    print "#\n";
    print "#: by: $job->{user} (on $job->{date})\n";
    if ($url_in_name) {
	print "#: note: $shortened_text\n";
	print "$job->{notes_url}\tX @{ $job->{coords} }\n";
    } else {
	print "#: url: $job->{notes_url}\n";
	print "$shortened_text\tX @{ $job->{coords} }\n";
    }
}
