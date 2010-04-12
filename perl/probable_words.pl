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
use lib 'modules';
use IPIG::ProbableWords;

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

=cut

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

my $proteins = IPIG::ProbableWords::readProteinSequence($word);
my $e;
if ($e = Exception::Class->caught('InvalidInputException')) {
    warn $e->error, "\n", $e->trace->as_string, "\n";
    warn join ' ', $e->euid, $e->egid, $e->uid, $e->gid, $e->pid, $e->time;
    
    exit;
}

IPIG::ProbableWords::calculate($word, $order, $proteins);

if ($reverse) {
    IPIG::ProbableWords::calculate(IPIG::ProbableWords::reverseWord($word,   # Reversed WORD
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
