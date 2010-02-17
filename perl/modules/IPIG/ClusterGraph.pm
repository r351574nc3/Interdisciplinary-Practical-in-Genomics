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
package IPIG::ClusterGraph;


=head1 Class C<ClusterGraph>

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

Constructs the C<ClusterGraph> from its attributes. None are required though. 
Initiates an array as its data store and saves a reference to it.

=head3 Parameters

=over

=item C<identity> - % Identity lower bound used for validation

=item C<alignment> - Alignment length lower bound used for validation

=back

=cut
sub new {
    my $class = shift;
    my @clusters;

    return bless {_identity  => shift,
                  _alignment => shift,
                  _clusters  => \@clusters}, $class;
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


#    foreach (@{$this->clusters()}) {
#        print "Adding a new cluster", "\n";
        
#        if 
        #my @clusters = @$_;
        #if ($#clusters > 0) {
        #    if ($toadd->compareCardinality($clusters[0]) == 0) {
        #        push(@clusters, $toadd);
        #        return;
        #    }
        #}
#    }
    
#    my @newClusterArr = ( $toadd );
   push(@{$this->clusters()}, $toadd);
}

=head2 Method C<addEdge>

=pod

Add an C<Edge> to a C<Cluster> in the C<ClusterGraph>. First, try to locate a
C<Cluster> with the same query id as the C<Edge> to add. If one cannot be found,
then instantiate one.

=head3 Parameters

=over

=item C<toadd> - C<Edge> instance to add

=back

=cut
sub addEdge {
    my $this = shift;
    my $toadd = shift;

    foreach my $cluster (@{$this->clusters()}) {
        if ($cluster->containsId($toadd->record()->query())) {
            $cluster->add($toadd);
               return;
        }
    }

    # There is no cluster with this gene
    my $newCluster = new IPIG::Cluster();
    $newCluster->add($toadd);
    $this->add($newCluster);
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

=head2 Getter/Setter C<identity>

=pod 

Getter for the the % identity lower bound.

=head3 Parameters

=over

=item C<identity> - % Identity lower bound used for validation

=back

=head3 Returns

=pod 

Gets the % identity lower bound

=cut
sub identity {
    my $this = shift;

    @_ ? $this->{_identity} = shift : return $this->{_identity};
}

=head2 Getter/Setter C<alignment>

=pod 

Getter for the the % alignment lower bound.

=head3 Parameters

=over

=item C<alignment> - Alignment length lower bound used for validation

=back

=head3 Returns

=pod 

Gets the alignment length lower bound

=cut
sub alignment {
    my $this = shift;

    @_ ? $this->{_alignment} = shift : return $this->{_alignment};
}

=head2 Getter C<clusterByQuery>

=pod

Gets a C<Cluster> from the graph by the query id. It will iterate through
the clusters until it finds one with the query id it's looking for.

=head3 Parameters

=over

=item C<query> id of the C<Cluster> to find

=back

=head3 Returns

=pod

A C<Cluster> instance

=cut
sub clusterByQuery {
    my $this = shift;
    my $query = shift;
    
    foreach my $cluster (@{$this->clusters()}) {
        $cluster->containsId($query) ? return $cluster : next;
    }
}

=head2 Method C<graph>

=pod 


=head3 Returns

=pod 

A sorted 2-dimensional array of the data to be represented in a visual graph

=cut
sub graph {
    my $this = shift;
    my $graph = [[],[]];
    my %graphHash;
    
    my $largest = 0;
#     print "Number of clusters is " . scalar @{$this->clusters()}, "\n";
    for (my $x = 0; $x < scalar @{$this->clusters()} - 1; $x++) {
#        print "Found cluster with size " . $this->clusters()->[$x]->size() . "\n";
#        print "id = " . $this->clusters()->[$x]->ids()->[0] . "\n";
        
        for (my $y = 0; $y < scalar @{$this->clusters()} - 1; $y++) {
            next if ($this->clusters()->[$x] eq $this->clusters()->[$y]); # Skip the same cluster
            
            # print $this->clusters()->[$x] . " ne " . $this->clusters()->[$y] . "\n";

            print "Trying to union $x with $y", "\n";
            my $newCluster = $this->clusters()->[$x]->union($this->clusters()->[$y]);
            if ($newCluster) {
                print "Got new cluster " . $newCluster->size(), "\n";
                $this->clusters()->[$x] = $newCluster;
                # delete $this->clusters()->[$y];
                # print "Removing cluster $y\n";
                splice(@{$this->clusters()}, $y, 1);
                $y--;
            }
        }

#        unless ($this->clusters()->[$x]) {
#            splice(@{$this->clusters()}, $x, 1);
#            $x--;
#        }
    }

    foreach my $cluster (@{$this->clusters()}) {
        next unless($cluster);
        next if ($cluster->size() < 2);
        $graphHash{$cluster->size()}++;
    }
    
    push(@{$graph->[0]}, keys %graphHash);
    push(@{$graph->[1]}, values %graphHash);

    return $graph;
}

return 1;
