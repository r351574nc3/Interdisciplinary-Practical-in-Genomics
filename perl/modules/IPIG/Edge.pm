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
package IPIG::Edge;

=head1 Class C<Edge>

=cut

=head2 Description 

=pod 

C<Edge> instances can be grouped together to form clusters (graphs of genes). A
C<Cluster> is basically like a digraph of genes where adjacent C<Edge> instancess are
grouped together. One C<Edge> is known to be adjacent to another C<Edge> if 
they belong to the same cluster (ie., have the same query id.) It is 
possible to union one C<Cluster> with another. This would produce C<Edge>
instances that were adjacent because of common I<subject id>

=head3 Author: I<Leo Przybylski (przybyls@arizona.edu)>

=cut

=head2 Default Constructor

=pod 

=head3 Parameters

=over

=item C<record> - a blast output record instance

=back

=cut
sub new {
    my $class = shift;

    return bless {_record => shift}, $class;
}

=head2 Method C<equals>

=pod 

If the C<query> and the C<subject> of C<tocompare> match the C<query> and C<subject> of
C<this> match, then we consider the C<Edge> instances to be equal.

=head3 Parameters

=over

=item C<tocompare> - C<Edge> instance to compare against

=back

=head3 Returns

=pod 

C<1> if they are equal; otherwise, returns C<0>

=cut
sub equals {
    my $this = shift;
    my $tocompare = shift;
    
    if ($this->record()->subject() eq $tocompare->record()->subject()) {
        return 1;
    }
    return 0;
}

=head2 Method C<isAdjacentTo>

=pod 

An C<Edge> is adjacent to another C<Edge> if their subjects match.

=head3 Parameters

=over

=item C<tocompare> - an C<Edge> instance to compare against

=back

=head3 Returns

=over

=item C<1> if C<this> is adjacent to C<tocompare>; otherwise, C<0>

=back

=cut
sub isAdjacentTo {
    my $this = shift;
    my $tocompare = shift;

    if ($this->record()->query() eq $tocompare->record()->subject() 
        || $this->record()->subject() eq $tocompare->record()->query()) {
        return 1;
    }
    return 0;
}

=head2 Getter/Setter C<record>

=pod 

Getter/Setter for the C<BlastRecord> of an C<Edge>

=head3 Parameters

=over

=item the record to set. If this parameter is ommitted, the method acts as a getter

=back

=head3 Returns

=pod 

Gets the C<BlastRecord>. Only returns something if there is no parameter present.

=cut
sub record {
    my $this = shift;
    
    return $this->{_record};
}


return 1;
