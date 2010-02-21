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
package IPIG::Graph;

=head1 Class C<Graph>

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
sub new {
    my $class = shift;

    return bless {_genes    => [], 
                  _edges    => []}, $class;
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
    
    if (!$this->contains($toadd)) {
        unless ($toadd->record()->isSelfHit()) {
            push(@{$this->genes()}, $toadd);
        }
        
        if (!$this->containsId($toadd->record()->query())) {
            push(@{$this->ids()}, $toadd->record()->query());
        }
    }

}

=head2 Method C<addEdge>

=pod

Adds an C<Gene> instance to the C<Cluster>

=head3 Parameters

=over

=item C<toadd> - C<Gene> instance to add

=back

=cut
sub addEdge {
    my $this   = shift;
    my %params = @_;
    my $source = $params{source};
    my $target = $params{target};
    
    return if (!validateEndpoints(source, destination));
    
    edges[source] |= 1 << target;
    edges[target] |= 1 << source;
}

=head2 Method C<addEdge>

=pod

Adds an C<Gene> instance to the C<Cluster>

=head3 Parameters

=over

=item C<toadd> - C<Gene> instance to add

=back

=cut
sub validateEndpoints {
    my $this = shift;
    my $source = shift;
    my $target = shift;
    
    return 0 if (contains($source));

    return 0 if (contains($target));

    return 1;
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


    foreach my $gene (@{$this->genes()}) {
        if ($gene->equals($tocompare)) {
            return 1;
        }
    }
    return 0;
}

=head2 Method C<isEdge>

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
sub isEdge {
    my %params = @_;
    my $source = $params{source};
    my $target = $params{target};

    return ((edges[source] & (1 << target)) == (1 << target)); 
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


    for (my $i = 0; $i < scalar @{$this->genes()}; $i++) {
        my $gene = $this->genes()->[$i];
        if ($gene->equals($tocompare)) {
            return $i;
        }
    }
    return -1;
}

=head2 Method C<removeEdge>

=pod

Locates and removes an C<Gene> from the C<Cluster>. This probably only happens
when an C<Gene> has been found to be invalid.

=head3 Parameters

=over

=item C<tocompare> - C<Gene> to locate and remove

=back

=cut
sub removeEdge{
    my $this = shift;
    my %params = @_;
    my $source = $params{source};
    my $target = $params{target};
    
    return if (!validateEndpoints(source, destination));
    
    edges[source] ^= 1 << target;
    edges[target] ^= 1 << source;
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
sub removeGene {
    my $this = shift;
    my $gene = shift;

    delete $this->genes()->[$gene];
    $this->{_size}--;
        
    $this->edges()->[$gene] = 0;
    for my $idx (0 .. scalar(@{$this->edges()})) {
        if ($idx == $gene) {
            continue;
        }                               
        
        $this->genes()->[$idx] ^= 1 << $gene;
    }
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

=head2 Method C<getAdjacent>

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
sub getAdjacent {
    my $this = shift;
    my $tocompare = shift;
    
    for my $gene (@{$tocompare->genes()}) {
        $this->hasGeneAdjacentTo($gene) ? return 1 : next;
    }
    return 0;
}

return 1;
