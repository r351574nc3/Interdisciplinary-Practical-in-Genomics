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
    require "BlastRecord.pm";
    import IPIG::BlastRecord;
    require "Cluster.pm";
    import IPIG::Cluster;
    require "Gene.pm";
    import IPIG::Gene;
    require "RecordHandler.pm";
    import IPIG::RecordHandler;
}

@ISA = (IPIG::RecordHandler);

=head2 Default Constructor

=pod 

Constructs a C<BlastRecordHandler> from its attributes

=head3 Parameters

=over

=item a C<ClusterGraph>. When it handles a record, an C<Gene> is added to the C<ClusterGraph>.
This makes the C<BlastRecordHandler> stateful.

=back

=cut
sub new {
    my $class = shift;
    my %alignments;
    
    return bless {_graph => shift, _alignments => \%alignments}, $class;
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
    my $this    = shift;
    my $record  = shift;

    my $cluster = $this->graph()->cluster($record->query());

    if (ref($cluster)) {
        # Validate all possible genes currently in the Cluster
        foreach my $gene (@{$cluster->genes()}) {
            $this->validate($gene);
        }
    }
    else {
        $this->graph()->add($record->query(), new IPIG::Cluster());
    }

    # Adding self-hit to the cluster. Not sure if this is right or not.
    # $this->graph()->addGene(new IPIG::Gene($record));
    $this->alignments()->{$record->query()} = $record->alignment();
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

=head2 Getter/Setter C<alignments>

=pod 

Getter/Setter for the alignment length requirements hash. Each alignment length 
is stored with the query id as the key.

=head3 Parameters

=over

=item C<alignments> to set (optional)

=back

=head3 Returns

=pod 

Gets the C<alignments>. Only returns something if there is no parameter present.

=cut
sub alignments {
    my $this = shift;
    
    @_ ? $this->{_alignments} = shift : return $this->{_alignments};
}

=head2 Method C<validate>

=pod 

Validates a C<BlastRecord> or C<Gene> using the self hit alignment information. If this record is valid,
we can use that information to determine if it is an gene or not.

A valid C<BlastRecord> has a % C<identity> larger than that of the requirement. The % C<identity>
requirement is determined at the point when the C<ClusterGraph> instance is created. That is, 
the C<ClusterGraph> knows what the requirement is. The same goes for the C<alignment> ratio
requirement. The C<ClusterGraph> also knows what that is. The C<alignment> ratio is determined by
the record alignment/self hit alignment. In order to obtain the self hit for a given record,
it is regarded that the C<Cluster> the C<BlastRecord> belongs in has an C<Gene> somewhere with
a subject that is the same as the C<BlastRecord>'s query which would make its query and subject
the same (a self hit.)

Take note that this only works if the C<Cluster> that the C<BlastRecord> belongs to has
a self hit. If there isn't one, then we just say it's valid. When the self hit is discovered,
this C<BlastRecord> will be re-evaluated.

=head3 Parameters

=over

=item C<record>    - The C<BlastRecord> or C<Gene> to validate

=back

=head3 Returns

=pod 

C<1> if the record is valid, C<0> otherwise.

=cut
sub validate {
    my $this      = shift;
    my $record    = shift;
    my $valid     = 1;          # Default to valid
    my $gene;

    # Since it can be a gene or record, we do some type-checking
    if ($record->isa(IPIG::Gene)) {
        $gene = $record;
        $record = $gene->record();
    }

    my $cluster  = $this->clusterForRecord($record);
    my $identReq = $this->graph()->identity();
    my $alignReq = $this->graph()->alignment();
    my $alignMax = $this->alignments->{$record->query()};

    if ($alignMax) { # Only validate if a self hit exists
        $valid &= (($identReq < $record->identity()) 
                   && ($alignReq < (($record->alignment()/$alignMax) * 100)));
    }
    else {
        $this->{_notvalidated}++;
    }
    
    if ($valid) {
        # This is an gene, so use the record to create an Gene instance
        # Genes can be compared against each other to form a Cluster (Graph
        # of genes)
        if (!ref($gene)) {
            # print "Adding a gene" . $record->subject(), "\n";
            $this->graph()->addGene(new IPIG::Gene($record));
        }
    }
    elsif (ref($gene) && $cluster) { # Gene was added to the cluster prematurely
        # Need to remove the $gene from the cluster
        $cluster->remove($gene);
    }
}

=head2 Method C<clusterForRecord>

=pod 

Lookup the C<Cluster> belonging to a C<BlastRecord>. Uses both C<query> and C<subject>
properties of the C<BlastRecord>

=head3 Parameters

=over

=item C<record>    - The C<BlastRecord> or C<Gene> to lookup a C<Cluster> for

=back

=head3 Returns

=pod 

A C<Cluster>

=cut
sub clusterForRecord {
    my $this   = shift;
    my $record = shift;

    my $cluster = $this->graph()->cluster($record->query());
    if (!$cluster) {
        # If you can't find one, shouldn't find the other. Check anyway.
        $cluster = $this->graph()->cluster($record->subject()); 
    }

    return $cluster;
}

return 1;
