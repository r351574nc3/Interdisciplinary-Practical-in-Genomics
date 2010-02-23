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
use warnings;
use lib 'modules/IPIG';
use GD::Graph::bars3d;
use Getopt::Std;

BEGIN {
    require "BlastParser.pm";
    import IPIG::BlastParser;
    require "BlastRecordHandler.pm";
    import IPIG::BlastRecordHandler;
    require "ClusterGraph.pm";
    import IPIG::ClusterGraph;
}

sub HELP_MESSAGE {
    print <<EOF;
Who dey?
EOF
}

$main::VERSION = "1.6";
$Getopt::Std::STANDARD_HELP_VERSION = 1;

=head1 Class C<Main>

=pod

The C<Main> program entry point. Usually, called through C<&Main::main()>

=head2 Description 

=pod 


=head3 Author: I<Leo Przybylski (przybyls@arizona.edu)>

=cut

package Main;

use base 'Exporter';

our @EXPORT = qw(main);

sub new {
    my $class = shift;
    return bless {}, $class;
}

=head2 Default Constructor

=pod 

Constructs the C<Main> object instance

=cut
sub graph {
    my $identity = shift;
    my $alignment = shift;
    my $clusters = shift()->($identity, $alignment);
    
    my $graphData = $clusters->graph();
    my $graph = new GD::Graph::bars3d(scalar(@{$graphData->[0]}) * 50, 768);
    $graph->set(
        x_label           => '# of Genes/Cluster',
        y_label           => '# of Clusters',
        title             => 'Gene Cluster Cardinality',
        show_values       => 1,
        bar_spacing       => 10,
        bar_shadow        => 9,
        shadowclr         => 'dred'
        );
    $graph->set_title_font(['/usr/share/fonts/truetype/msttcorefonts/arial.ttf'], 40);
    $graph->set_x_label_font('/usr/share/fonts/truetype/msttcorefonts/arial.ttf', 25);
    $graph->set_y_label_font('/usr/share/fonts/truetype/msttcorefonts/arial.ttf', 25);
    $graph->set_values_font('/usr/share/fonts/truetype/msttcorefonts/arial.ttf', 18);
    $graph->set_x_axis_font('/usr/share/fonts/truetype/msttcorefonts/arial.ttf', 18);
    $graph->set_y_axis_font('/usr/share/fonts/truetype/msttcorefonts/arial.ttf', 18);
    my $gd = $graph->plot($graphData);
    
    open(IMG, ">i${identity}_a${alignment}_graph.png") or die $!;
    binmode IMG;
    print IMG $gd->png;
}

sub testGraph {
    my $clusters = new IPIG::ClusterGraph();

    my $record1  = new IPIG::BlastRecord("AP206_contig00001_778-11", "AP206_contig00001_778-11");
    my $record2  = new IPIG::BlastRecord("AP206_contig00001_778-11", "AP206_contig00001_778-12");
    my $record3  = new IPIG::BlastRecord("AP206_contig00001_778-11", "AP206_contig00001_778-13");
    my $record4  = new IPIG::BlastRecord("AP206_contig00001_778-11", "sicca_contig00170_13535-14302");
    my $record5  = new IPIG::BlastRecord("AP206_contig00001_778-11", "sicca_contig00170_13535-14303");
    my $record6  = new IPIG::BlastRecord("AP206_contig00001_778-11", "sicca_contig00170_13535-14304");
    my $record7  = new IPIG::BlastRecord("AP206_contig00001_778-15", "AP206_contig00001_778-15");
    my $record8  = new IPIG::BlastRecord("AP206_contig00001_778-15", "sicca_contig00170_13535-14305");
    my $record9  = new IPIG::BlastRecord("AP206_contig00001_778-15", "AP206_contig00001_778-16");
    my $record10 = new IPIG::BlastRecord("AP206_contig00001_778-15", "sicca_contig00170_13535-14306");
    my $record11 = new IPIG::BlastRecord("AP206_contig00001_778-15", "AP206_contig00001_778-17");
    my $record12 = new IPIG::BlastRecord("AP206_contig00001_778-15", "sicca_contig00170_13535-14307");
    my $record13 = new IPIG::BlastRecord("AP206_contig00001_778-15", "AP206_contig00001_778-18");
    my $record14 = new IPIG::BlastRecord("AP206_contig00001_778-15", "sicca_contig00170_13535-143028");
                                  
    $clusters->addEdge(new IPIG::Edge($record1));
    $clusters->addEdge(new IPIG::Edge($record2));
    $clusters->addEdge(new IPIG::Edge($record3));
    $clusters->addEdge(new IPIG::Edge($record4));
    $clusters->addEdge(new IPIG::Edge($record5));
    $clusters->addEdge(new IPIG::Edge($record6));
    $clusters->addEdge(new IPIG::Edge($record7));
    $clusters->addEdge(new IPIG::Edge($record8));
    $clusters->addEdge(new IPIG::Edge($record9));
    $clusters->addEdge(new IPIG::Edge($record10));
    $clusters->addEdge(new IPIG::Edge($record11));
    $clusters->addEdge(new IPIG::Edge($record12));
    $clusters->addEdge(new IPIG::Edge($record13));
    $clusters->addEdge(new IPIG::Edge($record14));

    return $clusters
}

sub main {
    my $blast_file = pop(@ARGV);
    
    foreach my $identity ((30, 45, 60, 75, 90)) {
#    foreach my $identity ((30)) {               # For debugging
        foreach my $alignment ((50, 70, 90)) {
#        foreach my $alignment ((50)) {              # For debugging
            graph $identity, $alignment, sub {                
#            graph 30, 50, sub {                     # For debugging
                my $clusters = new IPIG::ClusterGraph(shift, shift);
                my $parser = new IPIG::BlastParser(new IPIG::BlastRecordHandler($clusters));
                $parser->parse($blast_file);
                
                return $clusters;
            }
        }
    }
}



Main::main();
