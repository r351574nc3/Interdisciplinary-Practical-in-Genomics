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

A cluster is basically like a set genes in a digraph of genes where 
adjacent genes are grouped together. One Gene is known to be adjacent 
to another gene if its query points to the subject or query of another
or its subject points to the query or subject of another.
...

Being that a Cluster is a Set, there is no duplication

=head3 Author: I<Leo Przybylski (przybyls@arizona.edu)>

=cut

BEGIN {
    require "Graph.pm";
    import IPIG::Graph;
}

sub new {
    my $class = shift;
    my %index;

    return bless {_index    => \%index,
                  _genes    => [],
                  _size     => 0,
                  _graph    => new IPIG::Graph(),
                  _ids      => []}, $class;
}

=head2 Method C<add>

=pod

Adds an C<Gene> instance to the C<Cluster>

=head3 Parameters

=over

=item C<toadd> - C<Gene> instance to add

=back

=cut
sub add {
    my $this = shift;
    my $toadd = shift;
    
    my $idx = $this->indexOf($toadd);
    if ($idx == -1) {
        unless ($toadd->record()->isSelfHit()) {
            push(@{$this->genes()}, $toadd);
            $this->{_index}->{$toadd->record()->subject()} = $this->{_size};
            $this->{_size}++;
        }
        
#        if (!$this->containsId($toadd->record()->query())) {
#            push(@{$this->ids()}, $toadd->record()->query());
#        }
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

A new C<Cluster> instance containing all C<Gene> instances from both C<Cluster> instances. If 
a union is not possible, nothing is returned

=cut
sub union {
    my $this = shift;
    my $other = shift;

    # print "Unioning cluster of size " . $this->size() . " with size " . $other->size() . "\n";

    return if (!$this->hasAdjacentGene($other));
    return if ($this->size() < 1 || $other->size() < 1);

    foreach my $gene (@{$other->genes()}) {
        # print "Adding $gene\n";
        $this->add($gene);
    }

    return $retval;
}

=head2 Method C<contains>

=pod

Traverses the C<Cluster> for a given C<Gene>

=head3 Parameters

=over

=item C<tocompare> - C<Gene> to test for existence

=back

=head3 Returns

=pod

C<1> if C<$tocompare> is contained in the C<Cluster>; C<0> otherwise.

=cut
sub contains {
    my $this = shift;
    my $tocompare = shift;


    return ($this->indexOf($tocompare) > -1)
}

=head2 Method C<indexOf>

=pod

Traverses the C<Cluster> looking for the array index of the C<Gene>

=head3 Parameters

=over

=item C<tocompare> - C<Gene> to find

=back

=head3 Returns

=pod

C<index> integer location of C<$tocompare> within the C<Cluster> array of C<Gene> instances; C<-1> otherwise.

=cut
sub indexOf {
    my $this = shift;
    my $tocompare = shift;

    my $index;

    if (ref $tocompare) {
        $index = $this->{_index}->{$tocompare->record()->subject()};
    }
    else {
        $index = $this->{_index}->{$tocompare};
    }

    if (!$index) {
        $index = -1;
    }
    
    return $index;
}

=head2 Method C<remove>

=pod

Locates and removes an C<Gene> from the C<Cluster>. This probably only happens
when an C<Gene> has been found to be invalid.

=head3 Parameters

=over

=item C<tocompare> - C<Gene> to locate and remove

=back

=cut
sub remove {
    my $this = shift;
    my $gene = shift;

    my $idx = $this->indexOf($gene);
    
    if ($idx > -1) { # Only remove a gene that exists
        # Do the remove via splicing out the element!    
        splice(@{$this->{_genes}}, $idx, 1);
    }
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

=head2 Getter C<graph>

=pod

=head3 Returns

=pod

A reference to an array instance containing C<Gene> instances for this C<Cluster>

=cut
sub graph {
    my $this = shift;

    return $this->{_graph};
}

=head2 Getter C<genes>

=pod

=head3 Returns

=pod

A reference to an array instance containing C<Gene> instances for this C<Cluster>

=cut
sub genes {
    my $this = shift;

    return $this->{_genes};
}

=head2 Getter C<ids>

=pod

=head3 Returns

=pod

A reference to an array instance containing C<Gene> instances for this C<Cluster>

=cut
sub ids {
    my $this = shift;

    return $this->{_ids};
}

=head2 Getter C<size>

=pod

=head3 Returns

=pod

The number of C<Gene> instances that are part of this C<Cluster>

=cut
sub size {
    my $this = shift;
    
    return $this->{_size};
}

=head2 Method C<hasAdjacentGene>

=pod

Compares this C<Cluster> to another to see if the two might have genes that 
are adjacent to each other

=head3 Parameters

=over

=item C<tocompare> - a C<Cluster> whose C<Gene> instances to compare to this one for 
    adjacency

=back

=head3 Returns

=pod

C<1> if C<tocompare> shares at least 1 adjacent gene with this C<Cluster> instance or
C<0> if it doesn't.

=cut
sub hasAdjacentGene {
    my $this = shift;
    my $tocompare = shift;
    
    for my $gene (@{$tocompare->genes()}) {
        $this->hasGeneAdjacentTo($gene) ? return 1 : next;
    }
    return 0;
}

=head2 Method C<hasGeneAdjacentTo>

=pod

Compares C<Gene> instances in this C<Cluster> to another to see if the the other 
is adjacent to any C<Gene> instances in this cluster.

=head3 Parameters

=over

=item C<tocompare> - a C<Gene> who compare to others in this C<Cluster> for adjacency

=back

=head3 Returns

=pod

C<1> if C<tocompare> shares at least 1 adjacent gene with this C<Cluster> instance or
C<0> if it doesn't.

=cut
sub hasGeneAdjacentTo {
    my $this = shift;
    my $tocompare = shift;
    
    foreach my $gene (@{$this->genes()}) {
        $gene->isAdjacentTo($tocompare) ? return 1 : next;
    }
    return 0;
}


=head2 Method C<compareCardinality>

=pod

Compares the cardinality (the number of C<Gene> instances) of this C<Cluster> instance
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

=head2 Getter C<geneByHit>

=pod

Gets an C<Gene> from the graph by the subject id. It will iterate through
the genes until it finds one with the subject id it's looking for.

=head3 Parameters

=over

=item C<subject> id of the C<Gene> to find

=back

=head3 Returns

=pod

An C<Gene> instance

=cut
sub geneByHit {
    my $this = shift;
    my $subject = shift;

    my $idx = $this->indexOf($subject);
    return $this->genes()->[$idx];
}

return 1;
