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

    return bless {_word       => $word,
                  _cds_count  => 0, 
                  _dus_count  => 0, 
                  _cds_length => 0}, $class;
}

=head2 Getter/Setter C<word>

=pod 

Getter/Setter for the word

=head3 Parameters

=over

=item C<word_id> to set (optional)

=back

=head3 Returns

=pod 

Gets the C<word_id>. Only returns something if there is no parameter present.

=cut
sub word {
    my $this = shift;

    @_ ? $this->{_word} = shift : return $this->{_word};
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
    my $this = shift;
    Log::Log4perl::get_logger()->debug("Starting the document");
}

=head2 Method C<import>

Handles importing of this package. Sets up Fasta::RecordHandler to be run from any package.

=head3 Parameters

=over

=item C<tags> - tags passed in by import 

=back

=cut
sub startRecord {
    my $this = shift;
    my %params = @_;

    
    #Log::Log4perl::get_logger()->debug("Starting a record " . $params{header});
    $this->{_cds_count}++;
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
    my $this = shift;
    my %params = @_;
    
    $params{record} =~ s/\s//g;
    $this->{_cds_length} += length($params{record});
    
    my $dus_count = 0;
    my $idx = -1;
    while(($idx = index($params{record}, $this->{_word}, $idx + 1)) > -1) {
        $dus_count++;
    }

    $idx = -1;
    while(($idx = index($params{record}, IPIG::complementWord($this->{_word}), $idx + 1)) > -1) {
        $dus_count++;
    }
    $this->{_dus_count} += $dus_count;

    if (exists $this->{_document}) {
        $this->{_document} .= "XXX";
    }
    else {
        $this->{_document} = '';
    }
    $this->{_document} .= $params{record};
}


sub dus_size {
    my $this = shift;
    return $this->{_dus_count};
}

sub cds_size {
    my $this = shift;
    return $this->{_cds_count};
}

sub cds_avg_length {
    my $this = shift;
    return $this->{_cds_length} / $this->{_cds_count};
}

=head2 Method C<import>

Handles importing of this package. Sets up Fasta::RecordHandler to be run from any package.

=head3 Parameters

=over

=item C<tags> - tags passed in by import 

=back

=cut
sub endDocument {
    my $this = shift;
    
    Log::Log4perl::get_logger()->debug("Ending the document");
    ProbableWords::calculate($this->{_word}, 4, $this->{_document});
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
    *{"Fasta\::RecordHandler::cds_size"} = *cds_size;
    *{"Fasta\::RecordHandler::dus_size"} = *dus_size;
    *{"Fasta\::RecordHandler::cds_avg_length"} = *cds_avg_length;
}

1;
