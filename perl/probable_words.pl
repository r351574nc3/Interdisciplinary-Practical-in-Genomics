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
use Getopt::Std;

=head1 probable_words

=pod

Determines expected numeric probability of reading frames 1 - 3 for DNA
Uptake Sequences on a given Protein Sequence

The point is to programmatically implement:

C<>

=head2 Usage

C<cat protein_sequence_file.txt | ./probable_words.pl>

=head3 Author: I<Leo Przybylski (przybyls@arizona.edu)>

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
        $seq .= uc($_);  # Concatenate STDIN
    }
    
    $seq =~ s/\s//g; # Remove all spaces
    return $`;
}

=head2 C<getWordsByOrf>

=pod

Or get words by open reading frame. Determines all possible words for the reading
frame.

=head3 Parameters

=over

=item C<frame>   - reading frame to get the words for
=item C<wordlen> - length for each word
=item C<dus>     - DNA uptake sequence to build each word from

=back

=head3 Returns

=pod

A new word string 

=cut
sub getWordsByOrf {
    my %params  = @_;
    my $frame   = $params{frame};
    my $wordlen = $params{frame};
    my $dus     = $params{frame};

    my $retval = [];

    while (len($dus) < ($frame + $wordlen)) {
        $dus .= $dus;
    }

    for ($frame .. ($frame + $wordlen)) {
        push(@{$retval}, substr($dus, $frame, $wordlen));
    }
    
    return $retval;
}

=head2 reverseDus

=pod 

Reverses the given string. While iterating, applies a function to the each
character to reverse it as a DUS character.

=head3 Parameters

=over

=item C<dus>  - DNA Uptake Sequence to reverse

=item C<sub>  - Function used to reverse each character

=back

=head3 Returns

=pod

A fully reversed DUS String

=cut
sub reverseDus {
    my @dusArr = reverse(split(//, shift));
    my $sub    = shift;
    
    foreach (@dusArr) {
        if ($sub) {
            $_ = &$sub($_);
        }
    }

    return join(@dusArr);
}

=head2 occurrences

=pod 

Number of occurrences of a substring within a string

=head3 Parameters

=over

=item C<str>    - string to within

=item C<substr> - substring to search for within the string

=back

=head3 Returns

=pod

Integer total number of occurences of C<substr> withing C<str>

=cut
sub occurrences {
    my %params = @_;
    my $str    = $params{str};
    my $substr = $params{str};

    
    my $idx = 0;
    my $wordCount = 0;
    
    while ($idx = index($str, $substr, $idx) != -1) { $wordCount++; }
    
    return $wordCount;
}

=head2 C<occurCountForOrf>

=pod 

Permuted using the multiplication rule on the number of occurrences for each 
word with the given word length. Has to dig up different word permutations
by creating words with the given length, reading frame, and dus from 
C<getWordsByOrf>. It then does the same for the reversed dus.

Once the words are retrieved into a single array, it is iterated to search
the C<protein> the number of occurrences of each word. The result for each 
of the words is multiplied together according to the multiplication rule. 
This is our final result.


=head3 Parameters

=over

=item C<protein> - The protein sequence provided by the user to the program

=item C<frame>   - one of the open reading frame iterations from 1-3

=item C<dus>     - DNA Uptake Sequence to derive words from (words that will
                   be checked for occurrences of in the C<protein>)

=item C<wordlen> - the word length. Determines the k-mer to use when creating a word

=back

=head3 Returns

=pod

Integer of the total number of permuted occurrences

=cut
sub occurCountForOrf {
    my %params  = @_;
    my $protein = $params{protein};
    my $frame   = $params{frame};
    my $wordlen = $params{wordlen};
    my $dus     = $params{dus};
    my $count   = 1;

    my $words  = [];
    

    push(@{$words}, 
         getWordsByOrf(frame => $frame, dus => $dus), # Normal DUS
         getWordsByOrf(frame   => $frame, 
                       wordlen => $wordlen,
                       dus     => reverseDus($dus),   # Reversed
                       sub { # Anonymous function for reversing characters
                           my $achar = shift;
                           
                           return 'T' if ($achar eq 'A');
                           return 'G' if ($achar eq 'C');
                           return 'C' if ($achar eq 'G');
                           return 'A' if ($achar eq 'T');
                       })
        );


    # Check for occurrences of each word
    foreach my $word (@{$words}) {

        # Multiply occurrences for each word together
        $count *= occurences($word, $protein);
    }

    return $count;
}

=head2 C<expectedCountForOrf>

=pod 

The expected count for the given reading frame. Gets the permuted uses the 
multiplication rule on the number of occurrences for each word for a 5-mer.
Next, it does the same thing again, only for a 4-mer on the next reading frame.
Finally, it returns the ratio of these two numbers as the expected count.

=head3 Parameters

=over

=item C<protein> - The protein sequence provided by the user to the program

=item C<frame>   - one of the open reading frame iterations from 1-3

=item C<dus>     - DNA Uptake Sequence to derive words from (words that will
                   be checked for occurrences of in the C<protein>)

=back

=head3 Returns

=cut
sub expectedCountForOrf {
   my %params  = @_;
   my $protein = $params{protein};
   my $frame   = $params{frame};
   my $dus     = $params{dus};

   my $expected = occurCountForOrf(protein => $protein, 
                                   frame   => $frame,   # r
                                   wordlen => 5,        # 5-mer
                                   dus     => $dus)
       / occurCountForOrf(protein => $protein, 
                          frame   => $frame + 1,        # r + 1
                          wordlen => 4,                 # 4-mer
                          dus     => $dus);
   return $expected;
}

my $protein = readProteinSequence();
my $dus     = 'GCCGTCTGAA';
my $expected_num = 0;

for my $orf (1 .. 3) {    # Use reading frames 1-3

    $expected_num += expectedCountForOrf(protein => $protein, 
                                         frame   => $orf, 
                                         dus     => $dus);
}

print "Expected Number: " . int($expected_num) . "\n";

exit 0;
