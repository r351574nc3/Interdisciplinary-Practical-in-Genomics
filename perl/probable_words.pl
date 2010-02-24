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

C<>,

=head2 Usage

C<cat your_protein_sequence_file | perl probable_words.pl>

=head3 Author: I<Leo Przybylski (przybyls@arizona.edu)>

=cut

=head1 Functions

=head2 C<readProteinSequence>

=pod 

Reads the Protein Sequence information from standard input, combines it into a single
String and finally removes all spaces from it.

=head3 Parameters

=over

=item dus - DUS to check for

=back

=head3 Returns

=pod

String representing the protein sequence to check probability against

=cut
sub readProteinSequence {
    my $dus    = shift;
    my %retval;

    print "Reading proteins\n";

    my $seq = '';
    my $header;
    while(<>) {
        chop;

        if ($_ =~ /^\>/) {
            if ($seq && validateDus(protein => $seq, dus => $dus)) {
                $seq =~ s/\s//g; # Remove all spaces
                $retval{$header} = $seq;
                $seq = '';
            }

            $header = $_;
            next;
        }

        $seq .= uc($_);  # Concatenate STDIN
    }

    # Finish last sequence
    if ($seq && $header) {
        if ($seq && validateDus(protein => $seq, dus => $dus)) {
            $seq =~ s/\s//g; # Remove all spaces
            $retval{$header} = $seq;
            undef $seq
        }
        else {
            print "Can't find $dus in $seq\n";
        }
        
    }
    
    return \%retval;
}

sub validateDus {
    my %params  = @_;
    my $protein = $params{protein};
    my $dus     = $params{dus};

    return unless ($protein && $dus);
    
    return index($protein, $dus) > -1
}

=head2 C<getWords>

=pod

chooses words from a DUS in order of the given length. Determines all possible words for length.

=head3 Parameters

=over

=item C<start>   - Presents the starting point. (optional)
=item C<wordlen> - length for each word
=item C<dus>     - DNA uptake sequence to build each word from

=back

=head3 Returns

=pod

A new word string 

=cut
sub getWords {
    my %params  = @_;
    my $start   = $params{start};
    my $wordlen = $params{wordlen};
    my $dus     = $params{dus};

    my $retval = [];
    $start = 0 unless($start);

    for ($start .. ($wordlen - 1)) {
        push(@{$retval}, substr($dus, $_, $wordlen));
    }

    return $retval;
}

=head2 C<getReversedWords>

=pod

chooses words from a DUS in order of the given length. Determines all possible words for length.
ONLY IN REVERSE!!!

=head3 Parameters

=over

=item C<start>   - Presents the starting point. (optional)
=item C<wordlen> - length for each word
=item C<dus>     - DNA uptake sequence to build each word from

=back

=head3 Returns

=pod

A new word string 

=cut
sub getReverseWords {
    my %params  = @_;
    my $start   = $params{start};
    my $wordlen = $params{wordlen};
    my $dus     = $params{dus};


    return getWords(  start => $start,
                    wordlen => $wordlen, 
                        dus => reverseDus($dus,   # Reversed DUS
            sub { # Anonymous function for reversing characters
                my $achar = shift;
                
                return 'T' if ($achar eq 'A');
                return 'G' if ($achar eq 'C');
                return 'C' if ($achar eq 'G');
                return 'A' if ($achar eq 'T');
                                          })
        );
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

    return join('', @dusArr);
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
    my %params  = @_;
    my $str     = $params{str};
    my $substr  = $params{substr};
    my $frame   = $params{frame};
    my $length = 10; # Assuming frame length is always 10. Ask about this.

    
    my $idx = 0;
    my $wordCount = 0;
    
    for (my $i = ($frame - 1); ($i + $length) < length($str); $i += $length) { 
        $wordCount++ if (index($str, $substr, $idx) != -1);
    }
    
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
    my $words   = $params{words};
    my $count   = 1;

    # Check for occurrences of each word
    foreach my $word (@{$words}) {
        # Multiply occurrences for each word together
        $count *= occurrences(str    => $protein,
                              substr => $word,
                              frame  => $frame);
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

=item C<words>   - upper and lower ratio words generated for the DUS we chose to use
                   

=back

=head3 Returns

Total expected number for the reading frame

=cut
sub expectedCountForOrf {
   my %params  = @_;
   my $protein = $params{protein};
   my $frame   = $params{frame};
   my $words   = $params{words};

   my $expected = occurCountForOrf(protein => $protein, 
                                   frame   => $frame,   # r
                                   words   => $words->[1])
       / occurCountForOrf(protein => $protein, 
                          frame   => $frame + 1,        # r + 1
                          words   => $words->[0]);
   return $expected;
}

my $dus = 'GCCGTCTGAA';
my $proteins = readProteinSequence($dus);
while (my ($header, $protein) = each %{$proteins}) {
    print $header, "\n";
    my $expected = 0;
    my $four_mers = getWords(  start => 1,
                             wordlen => 4, 
                                 dus => $dus);
    my $five_mers = getWords(wordlen => 5,
                                 dus => $dus);
    
    for my $orf (1 .. 3) {    # Use reading frames 1-3
        my $expectedOrf = expectedCountForOrf(protein => $protein, 
                                              frame => $orf, 
                                              words => [$four_mers, $five_mers]);
        $expected += $expectedOrf;
    print "Expected Number for ORF $orf: " . int($expectedOrf) . "\n";
    }
    
    print "Total Expected Number for ORF: " . int($expected) . "\n";
    
}
exit 0;
