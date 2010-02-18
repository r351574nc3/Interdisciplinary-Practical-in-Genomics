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

use strict;
use warnings;

=head1 probable_words

=pod

Determines expected numeric probability of reading frames 1 - 3 for DNA
Uptake Sequences on a given Protein Sequence

=head2 Usage

C<cat protein_sequence_file.txt | ./probable_words.pl>

=cut

=head1 Functions

=head2 C<readProteinSequence>

=pod 

Reads the Protein Sequence information from standard input, combines it into a single
String and finally removes all spaces from it.

=head3 Returns

=pod

String representing the protein sequence to check probability against

=cut
sub readProteinSequence {
    my $seq = '';
    while(<>) {
        chop;
        $seq .= $_;  # Concatenate STDIN
    }
    
    $seq =~ s/\s//g; # Remove all spaces
    return $seq;
}

=head2 C<getWordsByOrf>

=pod

Or get words by open reading frame. Determines all possible words for the reading
frame.

=head3 Parameters

=over

=item C<frame> - reading frame to get the words for

=back

=head3 Returns

=pod

An Array containing words 

=cut
sub getWordsByOrf {
    my %params = @_;
    my $frame = $params{frame};


    
}

sub dusReverse {
    my @dusArr = reverse(split(//, shift));
    my $sub    = shift;
    
    foreach (@dusArr) {
        $_ = &$sub($_);
    }

    return join(@dusArr);
}

my $protein = readProteinSequence();
my $dus     = 'GCCGTCTGAA';

for my $orf (1 .. 3) { # Use reading frames 1-3
    my $expected_num = 1; # Start with 1 because we're multiplying

    @words    = getWordsByOrf(frame => $orf, dus => $dus);
    @reversed = getWordsByOrf(frame => $orf, 
                              dus   => dusReverse($dus));
}
