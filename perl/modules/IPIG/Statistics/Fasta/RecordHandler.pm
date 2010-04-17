#!/usr/bin/perl
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

use Log::Log4perl qw(:easy);
use IPIG;
use IPIG::Statistics::ProbableWords;

=head1 Class C<RecordHandler>

=cut

=head2 Description 

 Allows for different types of record handling of Blast output. Used
 as an adapter passed to the BlastParser for different handling of 
 blast information.

=head3 Author: I<Leo Przybylski (przybyls@arizona.edu)>

=head3 Inherits From: C<RecordHandler>

=cut
package IPIG::Statistics::Fasta::RecordHandler;

=head2 Default Constructor

=pod 

Constructs a C<Parser> from its attributes

=head3 Parameters

=over

=item 

=back

=cut
sub new {
    my $class = shift;
    my $word  = shift;

    return bless {}, $class;
}


=head2 Getter/Setter C<document>

=pod 

Getter/Setter for the document

=head3 Parameters

=over

=item C<document_id> to set (optional)

=back

=head3 Returns

=pod 

Gets the C<document_id>. Only returns something if there is no parameter present.

=cut
sub document {
    my $this = shift;

    @_ ? $this->{_document} = shift : return $this->{_document};
}


=head2 Method C<import>

Handles importing of this package. Sets up Fasta::RecordHandler to be run from any package.

=head3 Parameters

=over

=item C<tags> - tags passed in by import 

=back

=cut
sub startDocument {
}

=head2 Method C<import>

Handles importing of this package. Sets up Fasta::RecordHandler to be run from any package.

=head3 Parameters

=over

=item C<tags> - tags passed in by import 

=back

=cut
sub startRecord {
}

=head2 Method C<import>

Handles importing of this package. Sets up Fasta::RecordHandler to be run from any package.

=head3 Parameters

=over

=item C<tags> - tags passed in by import 

=back

=cut
sub endRecord {
}

=head2 Method C<import>

Handles importing of this package. Sets up Fasta::RecordHandler to be run from any package.

=head3 Parameters

=over

=item C<tags> - tags passed in by import 

=back

=cut
sub record {
}


=head2 Method C<import>

Handles importing of this package. Sets up Fasta::RecordHandler to be run from any package.

=head3 Parameters

=over

=item C<tags> - tags passed in by import 

=back

=cut
sub endDocument {
}

=head2 Method C<import>

Handles importing of this package. Sets up Fasta::RecordHandler to be run from any package.

=head3 Parameters

=over

=item C<tags> - tags passed in by import 

=back

=cut
sub import {
    my $caller_pkg = caller();

    return 1 if $IMPORT_CALLED{$caller_pkg}++;

    *{"Fasta\::RecordHandler::new"} = *new;
    *{"Fasta\::RecordHandler::startDocument"} = *startDocument;
    *{"Fasta\::RecordHandler::endDocument"} = *endDocument;
    *{"Fasta\::RecordHandler::startRecord"} = *startRecord;
    *{"Fasta\::RecordHandler::endRecord"} = *endRecord;
    *{"Fasta\::RecordHandler::record"} = *record;
}

1;
