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
package IPIG::BlastRecordHandler;

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
    require "RecordHandler.pm";
    import IPIG::RecordHandler;
    require "BlastRecord.pm";
    import IPIG::BlastRecord;
    require "Cluster.pm";
    import IPIG::Cluster;
}

@ISA = (IPIG::RecordHandler);

=head2 Default Constructor

=pod 

Constructs a C<BlastRecordHandler> from its attributes

=head3 Parameters

=over

=item a C<ClusterGraph>. When it handles a record, an C<Edge> is added to the C<ClusterGraph>.
This makes the C<BlastRecordHandler> stateful.

=back

=cut
sub new {
    my $class = shift;

    return bless {_graph => shift}, $class;
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
    my $record = new IPIG::BlastRecord(@_);

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

    my $cluster = $this->graph()->clusterByQuery($record->query());

    if (ref($cluster)) {
        $cluster = new IPIG::Cluster();
    }

    # Validate all possible edges currently in the Cluster
    foreach my $edge (@{cluster->edges()}) {
        $this->validate($edge);
    }

    # Adding self-hit to the cluster. Not sure if this is right or not.
    $this->graph()->addEdge(new IPIG::Edge($record));

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

=head2 Getter/Setter C<graph>

=pod 

Getter/Setter for the cluster graph. 

=head3 Parameters

=over

=item C<graph> to set (optional)

=back

=head3 Returns

=pod 

Gets the C<graph>. Only returns something if there is no parameter present.

=cut
sub graph {
    my $this = shift;
    
    @_ ? $this->{_graph} = shift : return $this->{_graph};
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

=head2 Method C<validate>

=pod 

 Validates a C<BlastRecord> or C<Edge> using the self hit alignment information. If this record is valid,
 we can use that information to determine if it is an edge or not.

 A valid C<BlastRecord> has a % C<identity> larger than that of the requirement. The % C<identity>
 requirement is determined at the point when the C<ClusterGraph> instance is created. That is, 
 the C<ClusterGraph> knows what the requirement is. The same goes for the C<alignment> ratio
 requirement. The C<ClusterGraph> also knows what that is. The C<alignment> ratio is determined by
 the record alignment/self hit alignment. In order to obtain the self hit for a given record,
 it is regarded that the C<Cluster> the C<BlastRecord> belongs in has an C<Edge> somewhere with
 a subject that is the same as the C<BlastRecord>'s query which would make its query and subject
 the same (a self hit.)

=head3 Parameters

=over

=item C<record>    - The C<BlastRecord> or C<Edge> to validate

=back

=head3 Returns

=pod 

C<1> if the record is valid, C<0> otherwise.

=cut
sub validate {
    my $this      = shift;
    my $record    = shift;
    my $valid     = 0;
    my $edge;

    if ($record->isa(Edge)) {
        $edge = $record;
        $record = $edge->record();
    }

    my $cluster = $this->graph()->clusterByQuery($record->query());
    my $selfHit = $cluster->edgeByHit($record->query());

    my $identReq = $this->graph()->identity();
    my $alignReq = $this->graph()->alignment();

    $valid = (($identReq < $record->identity()) 
              && ($alignReq < ($record->alignment()/$selfHit->alignment())));
    
    if ($valid) {
        # This is an edge, so use the record to create an Edge instance
        # Edges can be compared against each other to form a Cluster (Graph
        # of genes)

        if (!ref($edge)) {
            $this->graph()->addEdge($edge);
        }
    }
    elsif (ref($edge)) {
        # Need to remove the $edge from the cluster
        $cluster->remove($edge);
    }
}

return 1;
