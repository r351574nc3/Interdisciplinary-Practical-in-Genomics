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

=head1 Class C<Fasta>

=head2 Description 

Module for function programming style api to statistical information on FASTA 
formatted files.

=head3 Author: I<Leo Przybylski (przybyls@arizona.edu)>

=cut
package IPIG::Statistics::Fasta;

use IPIG::Statistics::Fasta::Parser;
use IPIG::Statistics::Fasta::RecordHandler;
use IPIG::Statistics::Fasta::InvalidRecordHandler;

=head2 Method C<load>

Loads the given FastA file and runs statistics on its contents

=head3 Parameters

=over

=item C<input> - FastA formatted file

=back

=cut
sub load {
    my $input = shift;
    my $word  = shift;

    my %retval;

    my $order   = 4;
    my $reverse = 1;
    
    my $handler = new Fasta::RecordHandler($word);
    my $parser = new Fasta::Parser(record_handlers => [ $handler, 
                                                        new Fasta::InvalidRecordHandler() ]);
    $parser->parse($input);

    $retval{cds_size} = $handler->cds_size();
    $retval{dus_size} = $handler->dus_size();
    #$retval{dus_size} = parse_dus_size($input, $word);
    $retval{cds_avg_length} = $handler->cds_avg_length();
    $retval{expected} = $handler->expected();
    $retval{abundance} = $handler->abundance();

    return \%retval;
}

=head2 Method C<load>

Loads the given FastA file and runs statistics on its contents

=head3 Parameters

=over

=item C<input> - FastA formatted file

=back

=cut
sub parse_dus_size {
    my $input = shift;
    my $word = shift;

    open(FUZZNUC, "fuzznuc -sequence $input -pattern $word -complement Y -outfile /dev/stdout |tail -4 |");
    my $retval = 0;
    while (<FUZZNUC>) {
        if ($_ =~ /hitcount\:\s([0-9]+)/) {
            $retval = $1;
        }
    }
    close(FUZZNUC);
    return $retval;
}

=head2 Method C<import>

Handles importing of this package. Sets up Fasta::load to be run from any package.

=head3 Parameters

=over

=item C<tags> - tags passed in by import 

=back

=cut
sub import {
    my $caller_pkg = caller();

    return 1 if $IMPORT_CALLED{$caller_pkg}++;

    *{"$caller_pkg\::Fasta::load"} = *load;
    *{"$caller_pkg\::Fasta::parse_dus_size"} = *parse_dus_size;
}

1;
