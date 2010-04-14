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
use FileHandle;
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

=head1 NAME distribute_by_cog.pl
    
    distribute_by_cog - Distributes protein sequences by COG group into a file
    by the type name of that COG group. Also, produces a LaTeX table of COG
    distribution info.

    First, the COG groups are distributed into separate files. Then, the files
    are examined.

=head1 SYNOPSIS

    cat your_protein_sequence_file | perl distribute_by_cog.pl [OPTIONS] -i <input file> -w <word> -o <file to output to>

  Options:
    -(-i)nput           input file [required]
    -(-w)ord            Word to check subsequence occurences for. [required]
    --debug             The debug level. Debug levels are:
                        1 - DEBUG
                        2 - INFO
                        3 - WARN
                        4 - ERROR
                        5 - FATAL
                        [default=ERROR]
    -o                  file to output to [required]
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

=head3 REQUIRED LIBRARIES

=over

=item Log4Perl - Required for debugging, logging and output

=back

=head3 Author: I<Leo Przybylski (przybyls@arizona.edu)>

=head1 Functions

=head2 C<iterateCogsIn>

=pod 

Reads the Protein Sequence information from standard input, combines it into a single
String and finally removes all spaces from it.

=head3 Parameters

=over

=item input - Input file to read. If this is undefined, STDIN is used

=back

=head3 Returns

=pod

Hash of protein sequences

=cut
sub iterateCogsIn {
    my $input = shift;
    my $types = shift;
    my $each  = shift;

    get_logger()->info("Iterating proteins from ptt.\n");

    my $fh = \*STDIN;
    if ($input) {
        $fh = new FileHandle("<$input" . '.ptt') || die "Couldn't open $input\n";
    }

    my $ready;
    while(<$fh>) {
        if ($_ =~ /^Location/) {
            $ready = 1;
            next;
        }
        next unless($ready);        

        chop;

        my ($location, $strand, $length, $pid, $gene, $code, $cog, $product) = split(/\s/, $_);

        my $sequence = getSequenceByGeneLocation(input    => $input, 
                                                 location => $location,
                                                 gene     => $gene);
        
        my $groups = parseTypesFromCog($product);        
        if (scalar @{$groups} < 1) {
            push (@{$groups}, 'NA');
        }

        foreach my $group (@{$groups}) {
            my $seqout = new FileHandle(">>$group.ffn");
            print $seqout $sequence;
            $seqout->close();

            # Fast array existence check
            unless (exists {map { $_ => 1 } @{$types}}->{$group}) {
                push(@{$types}, $group);
            }
        }

        
        #&$each($input, split (/\s/, $_));
    }
}

=head2 C<getSequencesByGeneLocation>

=pod 

The main loop of execution

=head3 Parameters

=over

=item C<proteins> - The protein sequence provided by the user to the program

=item C<order>    - one of the open reading frame iterations from 1-3

=item C<word>    - upper and lower ratio words generated for the WORD we chose to use   

=back

=cut
sub getSequenceByGeneLocation {
    my %params = @_;
    my $input  = $params{input};
    my $gene   = $params{gene};
    my $loc    = $params{location};

    my ($cog_start, $cog_stop) = split(/\.\./, $loc);
    
    my $new_location  = min($cog_start, $cog_stop) . '-' . max($cog_start, $cog_stop);
    my $comp_location = 'c' . max($cog_start, $cog_stop) . '-' . min($cog_start, $cog_stop);
        
    my $fh = new FileHandle("<$input" . '.ffn');

    my $seq;
    while (defined <$fh>) {
        my $line = <$fh>;
        
        next unless ($line);

        if (($line =~ /^\>/)
            && (index($line, $new_location) > -1
                || index($line, $comp_location) > -1)
            && index($_, $gene) > -1) { # Header

            $seq = $line;

            while (defined <$fh>) {
                $line = <$fh>;
                if (defined $line) {
                    if ($line =~ /^\>/) {
                        return $seq;
                    }
                    $seq .= $line;
                }
            }
            return $seq;
        }
    }
}

=head2 C<parseTypesFromCog>

=pod 

The main loop of execution

=head3 Parameters

=over

=item C<proteins> - The protein sequence provided by the user to the program

=item C<order>    - one of the open reading frame iterations from 1-3

=item C<word>    - upper and lower ratio words generated for the WORD we chose to use   

=back

=cut
sub parseTypesFromCog {
    my $cog = shift;
    my @retval;
    
    if ($cog =~ /([a-zA-Z])+$/) {
        @retval = split(//,$1);
    }

    return \@retval;
}

=head2 C<max>

=pod 

The main loop of execution

=head3 Parameters

=over

=item C<proteins> - The protein sequence provided by the user to the program

=item C<order>    - one of the open reading frame iterations from 1-3

=item C<word>    - upper and lower ratio words generated for the WORD we chose to use   

=back

=cut
sub max { $_[$_[0] < $_[1]] }

=head2 C<min>

=pod 

The main loop of execution

=head3 Parameters

=over

=item C<proteins> - The protein sequence provided by the user to the program

=item C<order>    - one of the open reading frame iterations from 1-3

=item C<word>    - upper and lower ratio words generated for the WORD we chose to use   

=back

=cut
sub min { $_[$_[0] > $_[1]] }

=head2 C<distribute>

=pod 

The main loop of execution

=head3 Parameters

=over

=item C<proteins> - The protein sequence provided by the user to the program

=item C<order>    - one of the open reading frame iterations from 1-3

=item C<word>    - upper and lower ratio words generated for the WORD we chose to use   

=back

=head3 Returns

COG group types that can be examined separately

=cut
sub distribute {
    my $input    = shift;
    my $proteins = shift;

    my $types = [];

    iterateCogsIn($input, $types);

    return $types;
}

=head2 C<printTemplate>

=pod 

Given hash of data, prints out values in a template

=head3 Parameters

=over

=item params 

=back

=cut
sub printTemplate {
    my %params = @_;
    
    get_logger()->debug("Writing LaTeX to " . $params{file});
    my $fh = new FileHandle(">" . $params{file});

    print $fh <<EOF
\\documentclass[11pt,notitlepage]{article}
\\author{Leo Przybylski}
\\usepackage{graphicx}

\\begin{document}
\%\\begin{tabular}{\@{} c \@{}}
\%  \\hline \\\\
  \\begin{tabular}{\@{} p{2cm} p{4cm} p{1.2cm} p{1.2cm} p{1.1cm} p{2.5cm} \@{}}
    \\hline \\\\
     COG Groups & & No. of DUS& No. of CDS& Average CDS Length& Relative Abundance (95\\% CI)\\\\
\%  \\end{tabular}\\\\
    \\hline \\\\
\%  \\begin{tabular}{llrrrl}
EOF
;

#    foreach my $group (@{$params{groups}}) {
#        print $fh '\\' . $group{name} . "&"
#            . $group{description} . "&"
#            . $group{dus_count} . "&"
#            . $group{cds_count} . "&"
#            . $group{avg_cds} . "&"
#            . $group{abundance} . "\n";
#    }

print $fh <<EOF
    & & & & & \\\\
    \\hline
  \\end{tabular}
\%  \\hline 
\%\\end{tabular}
\\end{document}
EOF
}

my $debug = 4;
my $input; 
my $output;
my $word;

GetOptions( 'help|?' => \$help,
                 man => \$man, 
           'debug=s' => \$debug,
        'o|output=s' => \$output,
          'w|word=s' => \$word,
         'i|input=s' => \$input) or pod2usage(2);

pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

$debug = 10000 * $debug;
Log::Log4perl->easy_init($debug);

unless ($output) {
    get_logger()->fatal("An output file is required.");
    pod2usage(2);
}

unless ($word) {
    get_logger()->fatal("A word or DUS is required.");
    pod2usage(2);
}

unless ($input) {
    get_logger()->fatal("An input file is required.");
    pod2usage(2);
}

if ($input =~ /ptt$/ || $input =~ /ffn$/) {
    $input = substr($input, 0, length($input) - 4);
}
else {
    my $ffnfile = $input . '.ffn';
    my $pttfile = $input . '.ptt';
    unless (-e $ffnfile && -e $pttfile) {
        get_logger()->fatal("Both $ffnfile and $pttfile do not exist!");
        pod2usage(2);
    }
}

#my $proteins = readProteinSequence($input);
foreach my $type (@{distribute($input)}) {
    my $fh = new FileHandle("<$type.ffn");
    
}

printTemplate(file => $output);

exit 0;
__END__
