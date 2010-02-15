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
package ClusterMatrix;


=head1 Class C<ClusterMatrix>

=cut

=head2 Description 

=pod 

Used to contain clusters that are intended to be sorted. Clusters
are sorted according to the cardinality of edges per cluster. For 
example, clusters with 12 edges will be grouped in an array together.
The cardinality of that array determines the order in which these
clusters appear. Since the matrix is sorted in ascending order,
group 12 will appear after 10 and 11 due to its cluster cardinality.
Such information is used later to be depicted in a visual graph.

Right now, a multidimensional array is used to do this, but it might
be easier to use an insertion sort and apply the Observer pattern.
This would require more classes, and I'm not sure I care that much.

=head3 Author: I<Leo Przybylski (przybyls@arizona.edu)>

=cut

=head2 Default Constructor

=pod 

Constructs the C<ClusterMatrix> from its attributes. None are required though. 
Initiates an array as its data store and saves a reference to it.

=cut
sub new {
    my $class = shift;
    my @clusters;

    return bless {_clusters => \@clusters}, $class;
}


=head2 Method C<add>

=pod 

 Adds a cluster to the matrix. Compares the cardinality of the cluster $toadd 
 to the cardinality of each index of the matrix to determine where to add it. 
 Each index of the matrix is an array of clusters

=head3 Parameters

=over

=item  C<toadd> - Cluster to add

=back

=cut
sub add {
    my $this = shift;
    my $toadd = shift;

    foreach (@{$this->clusters()}) {
        my @clusters = @$_;
        if ($#clusters > 0) {
            if ($toadd->compareCardinality($clusters[0]) == 0) {
                push(@clusters, $toadd);
                return;
            }
        }
    }
    
    my @newClusterArr = ( $toadd );
    push(@{$this->clusters()}, \@newClusterArr);
}

sub addEdge {
    my $this = shift;
    my $toadd = shift;

    foreach my $clusterArr (@{$this->clusters()}) {
        foreach my $cluster (@{$clusterArr}) {
            if ($cluster->containsId($toadd->record()->query())) {
                print "Adding edge $toadd->record()->query()) to cluster\n";
                $cluster->add($toadd);
            }
        }
    }
}

=head2 Getter C<clusters>

=pod 

Getter for the the stored array of clusters. C<clusters> is a read-only attribute.

=head3 Returns

=pod 

Gets the reference to C<clusters> array.

=cut
sub clusters {
    my $this = shift;

    return $this->{_clusters};
}

sub graph {

    return [ 
        ["1st","2nd","3rd","4th","5th","6th","7th", "8th", "9th"], 
        [ 1, 2, 5, 6, 3, 1.5, 1, 3, 4], 
        ];
}

=head2 Method C<sort>

=pod 

Sorts C<clusters> according to the cardinality of each array of clusters contained.

=cut
sub sort {
}


return 1;
