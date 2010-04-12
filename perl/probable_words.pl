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

use Getopt::Long;
use Pod::Usage;
use Log::Log4perl qw(:easy);

use Exception::Class (
    'InvalidInputException',
    
    'MaskedSequenceException' => { 
        isa         => 'InvalidInputException',
        description => 'If the sequence given has masked (X) characters'
    }
    );

my $man = 0;
my $help = 0;

=head1 NAME probable_words.pl
    
    probable_words - Determines expected numeric probability of reading frames 1 - 3 for DNA
Uptake Sequences on a given Protein Sequence. 

Automatically, determines nucleutide or protein sequences read from STDIN

=head1 SYNOPSIS

    cat your_protein_sequence_file | perl probable_words.pl [options]

  Options:
    -(-w)ord            Word to check subsequence occurences for. [required]
    --debug             The debug level. Debug levels are:
                        1 - DEBUG
                        2 - INFO
                        3 - WARN
                        4 - ERROR
                        5 - FATAL
                        [default=ERROR]
    -(-n)on-coding      Sequence provided is a Non-Coding Sequence [default=no]
    -(-r)everse         Reverse the WORD [default=no]
    -(-o)rder           Order of the Markov Model to use. [default=2]
    -(-h)elp/?          brief help message
    -(-m)an             full documentation

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

Determines expected numeric probability of reading frames 1 - 3 for DNA
Uptake Sequences on a given Protein Sequence

=head3 Examples

=over 8

=item Check for probability in NM-MC58 nucleutide as a non-coding sequence with debug level DEBUG

C<cat ../NM-MC58.gbk | perl probable_words.pl -n --debug=1>

=item Check for probability in NM-MC58 nucleutide with debug level WARN. Check both the WORD and the reverse WORD.

C<cat ../NM-MC58.gbk | perl probable_words.pl -r --debug=3>

=item View the perldoc

C<perl probable_words.pl --man>

=back

=head3 Author: I<Leo Przybylski (przybyls@arizona.edu)>

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
    my $word     = $params{word};

    my $retval = [];
    $start = 0 unless($start);

    for ($start .. $wordlen) {
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
    my $word     = $params{word};


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

=head2 reverseWord

=pod 

Reverses the given string. While iterating, applies a function to the each
character to reverse it as a WORD character.

=head3 Parameters

=over

=item C<word>  - DNA Uptake Sequence to reverse

=item C<sub>  - Function used to reverse each character

=back

=head3 Returns

=pod

A fully reversed WORD String

=cut
sub reverseWord {
    my $word = reverse shift;
    my $sub    = shift;

    
    return &$sub($word);
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
    my $length = 3; # Assuming frame length is always 10. Ask about this.

    
    my $idx = 0;
    my $wordCount = 0;

    for (my $i = ($frame - 1); ($i + 3) < length($str); $i += 3) { 
        my $frame_substr = substr($str, $i, length($substr));
        $wordCount++ if (index($frame_substr, $substr) != -1);
    }

    return $wordCount;
}

=head2 C<occurCountForOrf>

=pod 

Permuted using the multiplication rule on the number of occurrences for each 
word with the given word length. Has to dig up different word permutations
by creating words with the given length, reading frame, and word from 
C<getWordsByOrf>. It then does the same for the reversed word.

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

=item C<words>   - upper and lower ratio words generated for the WORD we chose to use
                   

=back

=head3 Returns

Total expected number for the reading frame

=cut
sub expectedCountForOrf {
   my %params  = @_;
   my $protein = $params{protein};
   my $frame   = $params{frame};
   my $words   = $params{words};

   my $four_mer_result = occurCountForOrf(protein => $protein, 
                                          frame   => $frame + 1,        # r + 1
                                          words   => $words->[0]);
   my $five_mer_result = occurCountForOrf(protein => $protein, 
                                          frame   => $frame,   # r
                                          words   => $words->[1]);
 
   if ($four_mer_result > 1) {
       return int($five_mer_result / $four_mer_result);
   }
   return;
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
    my $proteins = shift;

    get_logger()->info("Checking WORD $word");

    while (my ($header, $protein) = each %{$proteins}) {
        get_logger()->info($header . "\n");
        my $expected = 0;
        my $k_mers = getWords(  start => 1,
                              wordlen => $order, 
                                 word => $word);
        my $k_plus_one_mers = getWords(wordlen => $order + 1,
                                       word => $word);
        
        for my $orf (1 .. 3) {    # Use reading frames 1-3
            my $expectedOrf = expectedCountForOrf(protein => $protein, 
                                                    frame => $orf, 
                                                    words => [$k_mers, $k_plus_one_mers]);
            if ($expectedOrf) {
                $expected += $expectedOrf;
            }
            else {
                $expectedOrf = "undefined";
            }
            get_logger()->info("Expected Number for ORF $orf: " . $expectedOrf . "\n");
        }
        
        get_logger()->info("Total Expected Number for ORF: " . $expected . "\n");
        
    }
}

# my $word = 'GCCGTCTGAA';
my $word; 
my $order   = 2;
my $ncds    = 0; # Non Coding Sequence
my $reverse = 0;
my $debug   = 4;

GetOptions( 'help|?' => \$help,
                 man => \$man, 
           'reverse' => \$reverse,
        'non-coding' => \$ncds,
            'word=s' => \$word, 
           'debug=s' => \$debug,
           "order=i" => \$order) or pod2usage(2);

pod2usage(1) if $help;
pod2usage(-exitstatus => 1) if (!$word);
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

$debug = 10000 * $debug;
Log::Log4perl->easy_init($debug);

my $proteins = readProteinSequence($word);
my $e;
if ($e = Exception::Class->caught('InvalidInputException')) {
    warn $e->error, "\n", $e->trace->as_string, "\n";
    warn join ' ', $e->euid, $e->egid, $e->uid, $e->gid, $e->pid, $e->time;
    
    exit;
}
print "Got here!\n";

calculate($word, $order, $proteins);

if ($reverse) {
    calculate(reverseWord($word,   # Reversed WORD
                         sub { # Anonymous function for reversing characters
                             my $retval = shift;
                             $retval =~ tr/ACGT/TGCA/;
                             return $retval;
                         }),
              $order,
              $proteins);
}
exit 0;
__END__
