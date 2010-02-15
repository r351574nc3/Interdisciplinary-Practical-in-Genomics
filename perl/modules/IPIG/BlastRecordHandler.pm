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
package BlastRecordHandler;

=head1 Class C<BlastRecordHandler>

=cut

=head2 Description 

=pod 

 Allows for different types of record handling of Blast output. Used
 as an adapter passed to the BlastParser for different handling of 
 blast information.

=head3 Author: I<Leo Przybylski (przybyls@arizona.edu)>

=head3 Inherits From: C<RecordHandler>

=cut

BEGIN {
    require "RecordHandler.class";
    import RecordHandler;
    require "BlastRecord.class";
    import BlastRecord;
    require "Cluster.class";
    import Cluster;
}

@ISA = (RecordHandler);

=head2 Default Constructor

=pod 

Constructs a C<BlastRecordHandler> from its attributes

=head3 Parameters

=over

=item a C<ClusterMatrix>. When it handles a record, an C<Edge> is added to the C<ClusterMatrix>.
This makes the C<BlastRecordHandler> stateful.

=back

=cut
sub new {
    my $class = shift;

    return bless {_clusters => shift}, $class;
}

=head2 Method C<handleRecord>

=pod 

Creates a C<BlastRecord> and handles it.

=head3 Parameters

=over

=item C<record> - an array of fields used to populate a C<BlastRecord>

=back

=cut
sub handleRecord {
    my $this = shift;
    my $record = new BlastRecord(@_);

    return $record;
}

=head2 Method C<isSelfHit>

=pod 

Handles I<self hit> blast records

=head3 Parameters

=over

=item C<record> - C<BlastRecord> instance

=back

=cut
sub selfHit {
    my $this = shift;
    my $record = shift;

    my $cluster = new Cluster();

    # Adding self-hit to the cluster. Not sure if this is right or not.
    $cluster->add(new Edge($record));
    $this->clusters()->add($cluster);

    $this->alignment($record->alignment());
   
}

=head2 Getter/Setter C<alignment>

=pod 

Getter/Setter for the alignment. Alignment is used to validate a C<BlastRecord>

=head3 Parameters

=over

=item C<alignment> to set (optional)

=back

=head3 Returns

=pod 

Gets the C<alignment>. Only returns something if there is no parameter present.

=cut
sub alignment {
    my $this = shift;

    @_ ? $this->{_alignment} = shift : return $this->{_alignment};
}

=head2 Getter/Setter C<clusters>

=pod 

Getter/Setter for the clusters. 

=head3 Parameters

=over

=item C<clusters> to set (optional)

=back

=head3 Returns

=pod 

Gets the C<clusters>. Only returns something if there is no parameter present.

=cut
sub clusters {
    my $this = shift;
    
    @_ ? $this->{_clusters} = shift : return $this->{_clusters};
}

=head2 Getter/Setter C<current>

=pod 

Getter/Setter for the current cluster. 

=head3 Parameters

=over

=item C<current> to set (optional)

=back

=head3 Returns

=pod 

Gets the C<current>. Only returns something if there is no parameter present.

=cut
sub current {
    my $this = shift;
    
    @_ ? $this->{_current} = shift : return $this->{_current};
}

=head2 Method C<validateRecord>

=pod 

 Validates this record using the self hit alignment information. If this record is valid,
 we can use that information to determine if it is an edge or not

=head3 Parameters

=over

=item C<record>    - The record to validate

=back

=head3 Returns

=pod 

C<1> if the record is valid, C<0> otherwise.

=cut
sub validateRecord {
    my $this      = shift;
    my $alignment = shift;
    my $record    = shift;
    my $valid     = 0;
    
    if ($valid) {
        # This is an edge, so use the record to create an Edge instance
        # Edges can be compared against each other to form a Cluster (Graph
        # of genes)
        my $edge = new Edge($record);
        $this->current()->add($edge);
    }
}

return 1;
