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
use Exception::Class (
    'InvalidInputException',
    
    'MaskedSequenceException' => { 
        isa         => 'InvalidInputException',
        description => 'If the sequence given has masked (X) characters'
    }
    );
=head1 NAME ProbableWords.pm

=cut
package IPIG::Statistics::ProbableWords;

our @EXPORT = ('readProteinSequence', 'calculate');

=head1 Functions

=head2 C<readProteinSequence>

=pod 

Reads the Protein Sequence information from standard input, combines it into a single
String and finally removes all spaces from it.

=head3 Parameters

=over

=item word - WORD to check for

=back

=head3 Returns

=pod

String representing the protein sequence to check probability against

=cut
sub readProteinSequence {
    my $word    = shift;
    my %retval;

    get_logger()->info("Reading proteins\n");

    my $seq = '';
    my $header;
    while(<>) {
        chop;
        if ($_ =~ /^\>/) {
#            if ($seq && validateWord(protein => $seq, word => $word)) {
            if ($header) {
                $seq =~ s/\s//g; # Remove all spaces
                if ($seq =~ /[^ACGTNX]/) {
                    eval { InvalidInputException->throw(error => "Invalid characters in $seq") };
                }
                $retval{$header} = $seq;
                $seq = '';
           }

            $header = $_;
            next;
        }
        else {
            $seq .= uc($_);  # Concatenate STDIN
        }
    }

    # Finish last sequence
    if ($seq && $header) {
        if ($seq && validateWord(protein => $seq, word => $word)) {
            $seq =~ s/\s//g; # Remove all spaces
            $retval{$header} = $seq;
            undef $seq
        }
        else {
            get_logger()->info("Can't find $word in $seq\n");
        }
        
    }
    
    return \%retval;
}

sub validateWord {
    my %params  = @_;
    my $protein = $params{protein};
    my $word    = $params{word};

    return unless ($protein && $word);
    
    return index($protein, $word) > -1
}

=head2 C<getWords>

=pod

chooses words from a WORD in order of the given length. Determines all possible words for length.

=head3 Parameters

=over

=item C<start>   - Presents the starting point. (optional)
=item C<wordlen> - length for each word
=item C<word>     - DNA uptake sequence to build each word from

=back

=head3 Returns

=pod

A new word string 

=cut
sub getWords {
    my %params  = @_;
    my $start   = $params{start};
    my $wordlen = $params{wordlen};
    my $word    = $params{word};

    my $retval = [];
    $start = 0 unless($start);
    my $wordcount = $wordlen + $start;

    for ($start .. $wordcount) {        
        Log::Log4perl::get_logger()->info("Using word ". substr($word, $_, $wordlen));
        push(@{$retval}, substr($word, $_, $wordlen));
    }

    return $retval;
}

=head2 C<getReversedWords>

=pod

chooses words from a WORD in order of the given length. Determines all possible words for length.
ONLY IN REVERSE!!!

=head3 Parameters

=over

=item C<start>   - Presents the starting point. (optional)
=item C<wordlen> - length for each word
=item C<word>     - DNA uptake sequence to build each word from

=back

=head3 Returns

=pod

A new word string 

=cut
sub getReversedWords {
    my %params  = @_;
    my $start   = $params{start};
    my $wordlen = $params{wordlen};
    my $word    = $params{word};

    return getWords(  start => $start,
                    wordlen => $wordlen, 
                       word => reverseWord($word,   # Reversed WORD
            sub { # Anonymous function for reversing characters
                my $retval = shift;
                $retval =~ tr/ACGT/TGCA/;
                return $retval;
            })
        );
}


=head2 occurrences

=pod 


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
    my $substr = $params{substr};

    my $retval = 0;

    my $pattern = '';
    foreach my $char (split(//, $substr)) {
        #$pattern .= $char;
        $pattern .= '[' . $char . 'X]';
    }

    $retval = () = $str =~ m/$pattern/g;

    Log::Log4perl::get_logger()->debug("Occurrences of $substr are $retval");
    return $retval;
}

=head2 C<occurCountForWords>

=pod 

Number of occurrences of a substring within a string

Permuted using the multiplication rule on the number of occurrences for each 
word with the given word length. Has to dig up different word permutations
by creating words with the given length, reading frame, and word from 
C<getWords>. It then does the same for the reversed word.

Once the words are retrieved into a single array, it is iterated to search
the C<protein> the number of occurrences of each word. The result for each 
of the words is multiplied together according to the multiplication rule. 
This is our final result.


=head3 Parameters

=over

=item C<protein> - The protein sequence provided by the user to the program

=item C<frame>   - one of the open reading frame iterations from 1-3

=item C<word>     - DNA Uptake Sequence to derive words from (words that will
                   be checked for occurrences of in the C<protein>)

=item C<wordlen> - the word length. Determines the k-mer to use when creating a word

=back

=head3 Returns

=pod

Integer of the total number of permuted occurrences

=cut
sub occurCountForWords {
    my %params  = @_;
    my $protein = $params{protein};
    #my $frame   = $params{frame};
    my $words   = $params{words};
    my $count   = 1;

    # Check for occurrences of each word
    foreach my $word (@{$words}) {
        # Multiply occurrences for each word together
        $count *= occurrences(str    => $protein,
                              substr => $word);
    }

    return $count;
}

=head2 C<expectedCount>

=pod 

The expected count for the given reading frame. Gets the permuted uses the 
multiplication rule on the number of occurrences for each word for a 5-mer.
Next, it does the same thing again, only for a 4-mer on the next reading frame.
Finally, it returns the ratio of these two numbers as the expected count.

=head3 Parameters

=over

=item C<protein> - The protein sequence provided by the user to the program

=item C<frame>   - one of the open reading frame iterations from 1-3

=item C<words>   - upper and lower ratio words generated for the WORD we chose to use
                   

=back

=head3 Returns

Total expected number for the reading frame

=cut
sub expectedCount {
   my %params  = @_;
   my $protein = $params{protein};
   #my $frame   = $params{frame};
   my $words   = $params{words};
   my $retval;

   my $four_mer_result = occurCountForWords(protein => $protein, 
                                            #frame   => $frame + 1,        # r + 1
                                            words   => $words->[0]);
   my $five_mer_result = occurCountForWords(protein => $protein, 
                                            #frame   => $frame,   # r
                                            words   => $words->[1]);


   Log::Log4perl::get_logger()->debug("Got fourmer results $four_mer_result");
   Log::Log4perl::get_logger()->debug("Got fivemer results $five_mer_result");
 
   if ($four_mer_result > 0) {
       $retval = int($five_mer_result / $four_mer_result);
       $retval = 1 if ($retval < 1);
   }
   return $retval;
}

=head2 C<calculate>

=pod 

The main loop of execution

=head3 Parameters

=over

=item C<proteins> - The protein sequence provided by the user to the program

=item C<order>    - one of the open reading frame iterations from 1-3

=item C<word>    - upper and lower ratio words generated for the WORD we chose to use   

=back

=cut
sub calculate {
    my $word     = shift;
    my $order    = shift;
    my $protein  = shift;
    my $frame    = shift;

    get_logger()->info("Checking WORD $word");
    my $k_mers = getWords(  start => 1,
                          wordlen => $order, 
                             word => $word);
    my $k_plus_one_mers = getWords(wordlen => $order + 1,
                                   word    => $word);
    
    Log::Log4perl::get_logger()->debug("Calculating reading frame $frame");
    my $expected = expectedCount(protein => IPIG::readingFrame($protein, $frame),
                                    words   => [$k_mers, $k_plus_one_mers]);
    
    Log::Log4perl::get_logger()->debug("Got expected value " . $expected);
    #get_logger()->info("Total Expected Number for ORF: " . $expected . "\n");
    return $expected;
}

sub get_logger() {
    return Log::Log4perl->get_logger();
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

    *{"ProbableWords::calculate"} = *calculate;
}
1;
__END__
