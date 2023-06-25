# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2023 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://www.rezic.de/eserte/
#

package GeoJSONFeatProps;

use strict;
use warnings;
our $VERSION = '0.01';

sub new { bless {}, shift }

sub manipulate_feature {
    my($self, $feature, undef, $directives) = @_;
    if ($directives->{by}) {
	$feature->{properties}->{name} = $directives->{by}->[0] . ' - ' . $feature->{properties}->{name};
    }
}

1;

__END__
