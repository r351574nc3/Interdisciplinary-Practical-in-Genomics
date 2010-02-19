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

=item C<frame> - reading frame to get the words for

=back

=head3 Returns

=pod

An Array containing words 

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

Number of occurrences of a substring within a string

=head3 Parameters

=over

=item 

=back

=head3 Returns

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

=head3 Returns

=cut
sub occurrences {
    my %params = @_;
    my $str    = $params{str};
    my $substr = $params{str};

    
    my $idx = 0;
    my $wordCount = 0;
    
    while ($idx = index($str, $substr, $idx) != -1) $wordCount++;
    
    return $wordCount;
}

=head2 occurrences

=pod 

Number of occurrences of a substring within a string

=head3 Parameters

=head3 Returns

=cut
sub occurCountForOrf {
    my %params  = @_;
    my $protein = $params{protein};
    my $frame   = $params{frame};
    my $wordlen = $params{wordlen}
    my $dus     = $params{dus};
    my $count   = 1;

    my $words  = [];
    
    push(@{$words}, 
         getWordsByOrf(frame => $frame, dus => $dus), # Normal DUS
         getWordsByOrf(frame   => $frame, 
                       wordlen => $wordlen
                       dus     => reverseDus($dus),   # Reversed
                       sub { # Anonymous function for reversing characters
                           my $char = shift;
                           
                           return 'T' if ($char eq 'A');
                           return 'G' if ($char eq 'C');
                           return 'C' if ($char eq 'G');
                           return 'A' if ($char eq 'T');
                       })
        );


    # Check for occurrences of each word
    foreach my $word (@{words}) {

        # Multiply occurrences for each word together
        $count *= occurences($word, $protein);
    }

    return $count;
}

=head2 occurrences

=pod 

Number of occurrences of a substring within a string

=head3 Parameters

=head3 Returns

=cut
sub expectedCountForOrf {
   my %params  = @_;
   my $protein = $params{protein};
   my $frame   = $params{frame};

   my $expected = occurCountForOrf(protein => $protein, 
                                   frame   => $orf, 
                                   wordlen => 5,        # 5-mer
                                   dus     => $dus)
       / occurCountForOrf(protein => $protein, 
                          frame   => $orf + 1,
                          wordlen => 4,                 # 4-mer
                          dus     => $dus);
   return $expected
}

my $protein = readProteinSequence();
my $dus     = 'GCCGTCTGAA';
my $expected_num = 0;

for my $orf (1 .. 3) {    # Use reading frames 1-3
    my $k = 5;            # I keep forgetting what k is for.

    $expected_num += expectedCountForOrf(protein => $protein, 
                                         frame   => $orf, 
                                         dus     => $dus);
}

print "Expected Number: " . int($expected_num) . "\n";

exit 0;
