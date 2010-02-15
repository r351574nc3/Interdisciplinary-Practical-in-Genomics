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

=head1 blast_calc1 Main

=cut 

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

    my $graph = new GD::Graph::bars3d(1024, 768);
    $graph->set(
        x_label           => 'Cluster Groups',
        y_label           => 'Clusters/Group',
        title             => 'Gene Cluster Cardinality',
        bar_spacing       => 18,
        bar_shadow        => 9,
        shadowclr         => 'dred'
        );
    $graph->set_title_font(['/usr/share/fonts/truetype/msttcorefonts/arial.ttf'], 44);
    $graph->set_x_label_font('/usr/share/fonts/truetype/msttcorefonts/arial.ttf', 30);
    $graph->set_y_label_font('/usr/share/fonts/truetype/msttcorefonts/arial.ttf', 30);
    $graph->set_values_font('/usr/share/fonts/truetype/msttcorefonts/arial.ttf', 20);
    $graph->set_x_axis_font('/usr/share/fonts/truetype/msttcorefonts/arial.ttf', 20);
    $graph->set_y_axis_font('/usr/share/fonts/truetype/msttcorefonts/arial.ttf', 20);
    my $gd = $graph->plot($clusters->graph());
    
    open(IMG, '>file.png') or die $!;
    binmode IMG;
    print IMG $gd->png;
}

sub testGraph {
    my $clusters = new ClusterMatrix();

    my $record1  = new BlastRecord("AP206_contig00001_778-11", "AP206_contig00001_778-11");
    my $record2  = new BlastRecord("AP206_contig00001_778-11", "AP206_contig00001_778-12");
    my $record3  = new BlastRecord("AP206_contig00001_778-11", "AP206_contig00001_778-13");
    my $record4  = new BlastRecord("AP206_contig00001_778-11", "sicca_contig00170_13535-14302");
    my $record5  = new BlastRecord("AP206_contig00001_778-11", "sicca_contig00170_13535-14303");
    my $record6  = new BlastRecord("AP206_contig00001_778-11", "sicca_contig00170_13535-14304");
    my $record7  = new BlastRecord("AP206_contig00001_778-15", "AP206_contig00001_778-15");
    my $record8  = new BlastRecord("AP206_contig00001_778-15", "sicca_contig00170_13535-14305");
    my $record9  = new BlastRecord("AP206_contig00001_778-15", "AP206_contig00001_778-16");
    my $record10 = new BlastRecord("AP206_contig00001_778-15", "sicca_contig00170_13535-14306");
    my $record11 = new BlastRecord("AP206_contig00001_778-15", "AP206_contig00001_778-17");
    my $record12 = new BlastRecord("AP206_contig00001_778-15", "sicca_contig00170_13535-14307");
    my $record13 = new BlastRecord("AP206_contig00001_778-15", "AP206_contig00001_778-18");
    my $record14 = new BlastRecord("AP206_contig00001_778-15", "sicca_contig00170_13535-143028");
                                  
    $clusters->addEdge(new Edge($record1));
    $clusters->addEdge(new Edge($record2));
    $clusters->addEdge(new Edge($record3));
    $clusters->addEdge(new Edge($record4));
    $clusters->addEdge(new Edge($record5));
    $clusters->addEdge(new Edge($record6));
    $clusters->addEdge(new Edge($record7));
    $clusters->addEdge(new Edge($record8));
    $clusters->addEdge(new Edge($record9));
    $clusters->addEdge(new Edge($record10));
    $clusters->addEdge(new Edge($record11));
    $clusters->addEdge(new Edge($record12));
    $clusters->addEdge(new Edge($record13));
    $clusters->addEdge(new Edge($record14));

    return $clusters
}

sub main {
    my $clusters = new ClusterMatrix();
    my $parser = new BlastParser(new BlastRecordHandler($clusters));
    $parser->parse(pop(@ARGV));

    #graph($clusters);

    graph(testGraph());
}

Main::main();
