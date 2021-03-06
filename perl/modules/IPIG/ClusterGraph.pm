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
are sorted according to the cardinality of genes per cluster. For 
example, clusters with 12 genes will be grouped in an array together.
The cardinality of that array determines the order in which these
clusters appear. Since the matrix is sorted in ascending order,
group 12 will appear after 10 and 11 due to its cluster cardinality.
Such information is used later to be depicted in a visual graph.

Right now, a multidimensional array is used to do this, but it might
be easier to use an insertion sort and apply the Observer pattern.
This would require more classes, and I'm not sure I care that much.

An index is kept (a C<HASH>) to key the index (the indices of the cluster
in the array storage) by a Gene. EVERY gene will points to an index
for a cluster.

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
    my %index;

    return bless {_identity  => shift,
                  _alignment => shift,
                  _index     => \%index,
                  _clusters  => [],
                  _size      => 0}, $class;
}


=head2 Method C<add>

=pod 

Adds a C<Cluster> to the graph. Sets the index to the last unoccupied index
and records it in the index C<HASH>. Finally, the cluster is appended to the
array store.


This is the only place where the size of the C<ClusterGraph> is incremented.

=head3 Parameters

=over

=item  C<toadd> - Cluster to add

=back

=cut
sub add {
    my $this  = shift;
    my $name  = shift;
    my $toadd = shift;

    $this->{_index}->{$name} = $this->size();
    push(@{$this->clusters()}, $toadd);
    # print "New size " . scalar @{$this->clusters()}, "\n";
    $this->{_size}++;
}

=head2 Method C<addGene>

=pod

Add an C<Gene> to a C<Cluster> in the C<ClusterGraph>. First, try to locate a
C<Cluster> with the same query id as the C<Gene> to add. Make sure that this
cluster is also referenced by the subject/hit id. If one cannot be found,
then instantiate one.

=head3 Parameters

=over

=item C<toadd> - C<Gene> instance to add

=back

=cut
sub addGene {
    my $this    = shift;
    my $toadd   = shift;
    my $qclust  = $this->cluster($toadd->record()->query());
    my $sclust  = $this->cluster($toadd->record()->subject());

    # Query cluster
    if ($qclust) {
        $qclust->add($toadd);

        if (!$sclust) {
            # Create back reference
            $this->{_index}->{$toadd->record()->subject()} = $this->{_index}->{$toadd->record()->query()};
        }
    }

    if ($sclust) {
        $sclust->add($toadd);

        if (!$qclust) {
            # Create back reference
            $this->{_index}->{$toadd->record()->query()} = $this->{_index}->{$toadd->record()->subject()};
        }
    }
    
    if (!$sclust && !$qclust) {
        my $newCluster = new IPIG::Cluster();
        $newCluster->add($toadd);
        $this->add($toadd->record()->query(), $newCluster);

        # Create back reference
        $this->{_index}->{$toadd->record()->subject()} = $this->{_index}->{$toadd->record()->query()};
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

=head2 Getter C<cluster>

=pod 

Getter for the the a specific C<cluster> by its index. C<cluster> is a read-only attribute.

=head3 Returns

=pod 

Gets the reference to C<clusters> array.

=cut
sub cluster {
    my $this = shift;
    my $name = shift;

    my $idx = $this->{_index}->{$name};

    $idx ? return $this->clusters()->[$idx] : return;
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

=head2 Getter C<size>

=pod

=head3 Returns

=pod

The number of C<Cluster> instances that are part of this C<ClusterGraph>

=cut
sub size {
    my $this = shift;
    
    return $this->{_size};
}

=head2 Method C<graph>

=pod 

Creates a data structure that can be used by the C<GD::Graph> module.

=head3 Returns

=pod 

A sorted 2-dimensional array of the data to be represented in a visual graph

=cut
sub graph {
    my $this = shift;
    my $graph = [[],[]];
    my %graphHash;

    foreach my $cluster (@{$this->clusters()}) {
        #next unless($cluster);
        next if ($cluster->size() < 1);
        # print "Got cluster with size ", $cluster->size(), "\n";
        $graphHash{$cluster->size()}++;
    }
    
    my @order = sort { $a <=> $b } keys %graphHash;
    #my @order = keys %graphHash;

    foreach my $key (@order) {
        push(@{$graph->[0]}, $key);
        push(@{$graph->[1]}, $graphHash{$key});        
    }

    return $graph;
}

return 1;
