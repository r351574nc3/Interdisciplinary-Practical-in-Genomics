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
package IPIG::Cluster;

=head1 Class C<Cluster>

=head2 Description

=pod

A cluster is basically like a set edges in a digraph of genes where 
adjacent edges are
grouped together. One Edge is known to be adjacent to another edge if 
...

Being that a Cluster is a Set, there is no duplication

=head3 Author: I<Leo Przybylski (przybyls@arizona.edu)>

=cut
sub new {
    my $class = shift;
    my @edges = ();
    my @ids   = ();

    return bless {_edges => \@edges, _ids => \@ids}, $class;
}

=head2 Method C<add>

=pod

Adds an C<Edge> instance to the C<Cluster>

=head3 Parameters

=over

=item C<toadd> - C<Edge> instance to add

=back

=cut
sub add {
    my $this = shift;
    my $toadd = shift;
    
    if (!$this->contains($toadd)) {
        push(@{$this->edges()}, $toadd);
        push(@{$this->ids()}, $toadd->record()->query());
    }    
}

=head2 Method C<union>

=pod

Unions this C<Cluster> instance with another C<Cluster> instance. The result
is a completely new C<Cluster>. 

=head3 Parameters

=over

=item C<other> - a C<Cluster> instance to union with this

=back

=head3 Returns

=pod 

A new C<Cluster> instance containing all C<Edge> instances from both C<Cluster> instances.

=cut
sub union {
    my $this = shift;
    my $other = shift;
    
    my $retval = new Cluster();
}

=head2 Method C<contains>

=pod

=head3 Parameters

=over

=item C<tocompare> - 

=back

=head3 Returns

=pod

C<1> if C<$tocompare> is contained in the C<Cluster>; C<0> otherwise.

=cut
sub contains {
    my $this = shift;
    my $tocompare = shift;


    foreach my $edge (@{$this->edges()}) {
        if ($edge->equals($tocompare)) {
            return 1;
        }
    }
    return 0
}

=head2 Method C<containsId>

=pod

=head3 Parameters

=over

=item C<tocompare> - 

=back

=head3 Returns

=pod

C<1> if C<$tocompare> is contained in the C<Cluster>; C<0> otherwise.

=cut
sub containsId {
    my $this = shift;
    my $tocompare = shift;


    foreach my $id (@{$this->ids()}) {
        if ($id eq $tocompare) {
            return 1;
        }
    }
    return 0
}

=head2 Getter C<edges>

=pod

=head3 Returns

=pod

A reference to an array instance containing C<Edge> instances for this C<Cluster>

=cut
sub edges {
    my $this = shift;

    return $this->{_edges};
}

=head2 Getter C<ids>

=pod

=head3 Returns

=pod

A reference to an array instance containing C<Edge> instances for this C<Cluster>

=cut
sub ids {
    my $this = shift;

    return $this->{_ids};
}

=head2 Getter C<size>

=pod

=head3 Returns

=pod

The number of C<Edge> instances that are part of this C<Cluster>

=cut
sub size {
    my $this = shift;
    
    return scalar(@{$this->edges()});
}

=head2 Method C<hasAdjacentEdge>

=pod

Compares this C<Cluster> to another to see if the two might have edges that 
are adjacent to each other

=head3 Parameters

=over

=item C<tocompare> - a C<Cluster> whose C<Edge> instances to compare to this one for 
    adjacency

=back

=head3 Returns

=pod

C<1> if C<tocompare> shares at least 1 adjacent edge with this C<Cluster> instance or
C<0> if it doesn't.

=cut
sub hasAdjacentEdge {
    my $this = shift;
    my $tocompare = shift;
    
    for my $edge (@{$tocompare->edges()}) {
        $this->hasEdgeAdjacentTo($edge) ? return 1 : next;
    }
    return 0;
}

=head2 Method C<hasEdgeAdjacentTo>

=pod

Compares C<Edge> instances in this C<Cluster> to another to see if the the other 
is adjacent to any C<Edge> instances in this cluster.

=head3 Parameters

=over

=item C<tocompare> - a C<Edge> who compare to others in this C<Cluster> for adjacency

=back

=head3 Returns

=pod

C<1> if C<tocompare> shares at least 1 adjacent edge with this C<Cluster> instance or
C<0> if it doesn't.

=cut
sub hasEdgeAdjacentTo {
    my $this = shift;
    my $tocompare = shift;
    
    foreach my $edge (@{$this->edges()}) {
        $edge->isAdjacentTo($tocompare) ? return 1 : next;
    }
    return 0;
}


=head2 Method C<compareCardinality>

=pod

Compares the cardinality (the number of C<Edge> instances) of this C<Cluster> instance
to another C<Cluster> instance.

=head3 Parameters

=over

=item C<tocompare> - a C<Cluster> instance to compare this against

=back

=head3 Returns

=over

=item C<-1> if this C<Cluster> is smaller in cardinality than C<tocompare>

=item C<0> if this C<Cluster> is shares the same cardinality as C<tocompare>

=item C<1> if this C<Cluster> is larger in cardinality than C<tocompare>

=back

=cut
sub compareCardinality {
    my $this = shift;
    my $tocompare = shift;
    
    if (ref $tocompare) {
        if ($this->size() == $tocompare->size()) {
            return 0;
        }
        elsif ($this->size() > $tocompare->size()) {
            return 1;
        }
        else {
            return -1;
        }
    }

    return -1;
}

return 1;
