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
package IPIG::RecordHandler;

=head1 Class C<RecordHandler>

=cut

=head2 Description 

=pod 

Abstract class for creating instances used by the BlastParser for handling
records.

=head3 Author: I<Leo Przybylski (przybyls@arizona.edu)>

=cut

=head2 Default Constructor

=pod 

Constructs the C<RecordHandler> from its attributes. None are required though.

=cut
sub new {
    my $class = shift;

    return bless {}, $class;
}


=head2 Method C<handleRecord>

=pod

Stub method for handling blast output records. This is the method that the 
C<BlastParser> will call when it encounters a record.

=cut
sub handleRecord {
    my $this   = shift;
}

=head2 Method C<handleRecord>

=pod

Stub method for validating blast output records. Typically, the result will
be an C<Edge> added to a C<Cluster>

=cut
sub validateRecord {
    my $this      = shift;
    my $alignment = shift;
    my $record    = shift;
}

return 1;
