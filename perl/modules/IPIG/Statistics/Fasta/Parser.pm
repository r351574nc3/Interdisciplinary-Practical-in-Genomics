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
use FileHandle;

=head1 Class C<Parser>

=cut

=head2 Description 

 Allows for different types of record handling of Blast output. Used
 as an adapter passed to the BlastParser for different handling of 
 blast information.

=head3 Author: I<Leo Przybylski (przybyls@arizona.edu)>

=cut
package IPIG::Statistics::Fasta::Parser;

sub new {
    my $class = shift;
    my %params = @_;

    return bless {_record_handlers => $params{record_handlers}}, $class;
}

=head2 Method C<parse>

Parses a FastA file. Uses RecordHandler instances to handle each record

=head3 Parameters

=over

=item C<input> - File to parse

=back

=cut
sub parse {
    my $this  = shift;
    my $input = shift;

    get_logger()->info("Opening $input");
    
    my $fh = new FileHandle("< $input");
    $this->notify_record_handlers(startDocument => 1);

    my $started = 0;
    my $header;
    my $record;
    while (<$fh>) {
        chop();
        if ($_ =~ /^>/) {
            if ($started) {
                $this->notify_record_handlers(endRecord => 1);
            }
            else {
                $started = 1;
            }
            
            $header = $_;
            $record = undef;
            $this->notify_record_handlers(startRecord => 1,
                                          header      => $header);
        }
        else {
            $this->notify_record_handlers(record => $_,
                                          header => $header);
            $record .= $_;
        }
    }
    $this->notify_record_handlers(endDocument => 1);
}

sub notify_record_handlers {
    my $this   = shift;
    my %params = @_;

    foreach my $rh (@{$this->record_handlers()}) {
        if (exists $params{startRecord}) {
            $rh->startRecord(header => $params{header});
        }
        elsif (exists $params{record}) {
            $rh->record(record => $params{record}, header=> $params{header});
        }
        elsif (exists $params{startDocument}) {
            $rh->startDocument();
        }
        elsif (exists $params{endDocument}) {
            $rh->endDocument();
        }
        else {
            $rh->endRecord();
        }
    }
}

=head2 Getter/Setter C<record_handlers>

=pod 

Getter/Setter for the record_handlers

=head3 Parameters

=over

=item C<record_handlers> to set (optional)

=back

=head3 Returns

=pod 

Gets the C<record_handlers>. Only returns something if there is no parameter present.

=cut
sub record_handlers {
    my $this = shift;

    @_ ? $this->{_record_handlers} = shift : return $this->{_record_handlers};
}

sub get_logger {
    return Log::Log4perl::get_logger();
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

    *{"Fasta\::Parser::new"} = *new;
    *{"Fasta\::Parser::parse"} = *parse;
    *{"Fasta\::Parser::notify_record_handlers"} = *notify_record_handlers;
    *{"Fasta\::Parser::record_handlers"} = *record_handlers;
    *{"Fasta\::Parser::get_logger"} = *get_logger;
}

1;
