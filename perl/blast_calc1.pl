#!/usr/bin/perl
######################################################################
# Copyright 2010 Leo Przybylski Licensed under the
# Educational Community License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may
# obtain a copy of the License at
#
# http://www.osedu.org/licenses/ECL-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an "AS IS"
# BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
# or implied. See the License for the specific language governing
# permissions and limitations under the License.
######################################################################

use strict;
use lib 'modules/IPIG';
use GD::Graph::bars3d;

BEGIN {
    require "BlastParser.class";
    import BlastParser;
    require "BlastRecordHandler.class";
    import BlastRecordHandler;
    require "ClusterMatrix.class";
    import ClusterMatrix;
}



package Main;

use strict;

use warnings;

use base 'Exporter';

our @EXPORT = qw(main);

sub new {
    my $class = shift;
    return bless {}, $class;
}

sub graph {
    my $clusters = shift;
}

sub main {
    my $clusters = new ClusterMatrix();
    my $parser = new BlastParser(new BlastRecordHandler($clusters));
    $parser->parse(pop(@ARGV));

    graph($clusters);

    my @data = (
        ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"],
        [ 1203,  3500,  3973,  2859,  3012,  3423,  1230]
        );
    my $graph = new GD::Graph::bars3d( 400, 300 );
    $graph->set(
        x_label           => 'Day of the week',
        y_label           => 'Number of hits',
        title             => 'Daily Summary of Web Site',
        );
    my $gd = $graph->plot( \@data );
    
    open(IMG, '>file.png') or die $!;
    binmode IMG;
    print IMG $gd->png;
}

Main::main();
