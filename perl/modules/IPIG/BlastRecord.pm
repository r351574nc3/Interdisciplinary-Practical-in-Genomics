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
package IPIG::BlastRecord;

=head1 Class C<BlastRecord>

=cut

=head2 Description 

=pod 

Class representation of line items from blast output. C<BlastRecord> instances 
have 

=over

=item query id

=item subject id

=item identity

=item alignment length

=back

=head3 Author: I<Leo Przybylski (przybyls@arizona.edu)>

=cut

=head2 Default Constructor

=pod 

Constructs the C<BlastRecord> from its attributes. None are required though.

=head3 Parameters

=over

=item C<query> id

=item C<subject> id

=item C<identity>

=item C<alignment> length

=item C<mismatches> - undetermined

=item C<qstart> - undetermined

=item C<qend> - undetermined

=item C<sstart> - undetermined

=item C<send> - undetermined

=item C<evalue> - undetermined

=back

=cut
sub new {
    my $this = bless {}, shift;

   
    $this->query(shift);
    $this->subject(shift);
    $this->identity(shift);
    $this->alignment(shift);
    $this->mismatches(shift);
    $this->qstart(shift);
    $this->qend(shift);
    $this->sstart(shift);
    $this->send(shift);
    $this->evalue(shift);

    return $this
}

=head2 Method C<isSelfHit>

=pod

A Record is considered a I<self hit> if its query and subject are the same. This
method compares them and returns the results. It's case-sensitive.

=head3 Returns

=pod 

C<1> if is I<self hit>; otherwise, returns C<0>

=cut
sub isSelfHit {
    my $this = shift;
    $this->query() eq $this->subject() ? 1 : 0;
}

=head2 Getter/Setter C<query>

=pod 

Getter/Setter for the query

=head3 Parameters

=over

=item C<query_id> to set (optional)

=back

=head3 Returns

=pod 

Gets the C<query_id>. Only returns something if there is no parameter present.

=cut
sub query {
    my $this = shift;

    @_ ? $this->{_query} = shift : return $this->{_query};
}

=head2 Getter/Setter C<subject>

=pod 

Getter/Setter for the subject

=head3 Parameters

=over

=item C<subject_id> to set (optional)

=back

=head3 Returns

=pod 

Gets the C<subject_id>. Only returns something if there is no parameter present.

=cut
sub subject {
    my $this = shift;

    @_ ? $this->{_subject} = shift : return $this->{_subject};
}

=head2 Getter/Setter C<identity>

=pod 

Getter/Setter for the identity

=head3 Parameters

=over

=item C<identity> to set (optional)

=back

=head3 Returns

=pod 

Gets the C<identity>. Only returns something if there is no parameter present.

=cut
sub identity {
    my $this = shift;

    @_ ? $this->{_identity} = shift : return $this->{_identity};
}

=head2 Getter/Setter C<alignment>

=pod 

Getter/Setter for the alignment

=head3 Parameters

=over

=item C<alignment> to set (optional)

=back

=head3 Returns

=pod 

Gets the alignment. Only returns something if there is no parameter present.

=cut
sub alignment {
    my $this = shift;

    @_ ? $this->{_alignment} = shift : return $this->{_alignment};
}

=head2 Getter/Setter C<mismatches>

=pod 

Getter/Setter for the mismatches

=head3 Parameters

=over

=item C<mismatches> to set (optional)

=back

=head3 Returns

=pod 

Gets the mismatches. Only returns something if there is no parameter present.

=cut
sub mismatches {
    my $this = shift;

    @_ ? $this->{_mismatches} = shift : return $this->{_mismatches};
}

=head2 Getter/Setter C<qstart>

=pod 

Getter/Setter for the qstart

=head3 Parameters

=over

=item C<qstart> to set (optional)

=back

=head3 Returns

=pod 

Gets the qstart. Only returns something if there is no parameter present.

=cut
sub qstart {
    my $this = shift;

    @_ ? $this->{_qstart} = shift : return $this->{_qstart};
}

=head2 Getter/Setter C<qend>

=pod 

Getter/Setter for the qend

=head3 Parameters

=over

=item C<qend> to set (optional)

=back

=head3 Returns

=pod 

Gets the qend. Only returns something if there is no parameter present.

=cut
sub qend {
    my $this = shift;

    @_ ? $this->{_qend} = shift : return $this->{_qend};
}

=head2 Getter/Setter C<sstart>

=pod 

Getter/Setter for the sstart

=head3 Parameters

=over

=item C<sstart> to set (optional)

=back

=head3 Returns

=pod 

Gets the sstart. Only returns something if there is no parameter present.

=cut
sub sstart {
    my $this = shift;

    @_ ? $this->{_sstart} = shift : return $this->{_sstart};
}

=head2 Getter/Setter C<send>

=pod 

Getter/Setter for the send

=head3 Parameters

=over

=item C<send> to set (optional)

=back

=head3 Returns

=pod 

Gets the send. Only returns something if there is no parameter present.

=cut
sub send {
    my $this = shift;

    @_ ? $this->{_send} = shift : return $this->{_send};
}

=head2 Getter/Setter C<evalue>

=pod 

Getter/Setter for the evalue

=head3 Parameters

=over

=item C<evalue> to set (optional)

=back

=head3 Returns

=pod 

Gets the evalue. Only returns something if there is no parameter present.

=cut
sub evalue {
    my $this = shift;

    @_ ? $this->{_evalue} = shift : return $this->{_evalue};
}

        

return 1;
