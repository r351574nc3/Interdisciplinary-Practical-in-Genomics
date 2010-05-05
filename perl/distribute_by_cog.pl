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

use lib 'modules';
use IPIG::Statistics::Fasta;



use Exception::Class (
    'InvalidInputException',
    
    'SequenceNotFoundException' => { 
        description => 'A sequence in a ptt file could not be located in a component ffn file.'
    }
    );

my $man = 0;
my $help = 0;

my $cog_desc_map = {
    All => "All means all.",
    A => "RNA processing and modification",
    B => "Chromatin structure and dynamics",
    C => "Energy production and conversion",
    D => "Cell cycle control, mitosis and meiosis",
    E => "Amino acid transport and metabolism",
    F => "Nucleotide transport and metabolism",
    G => "Carbohydrate transport and metabolism",
    H => "Coenzyme transport and metabolism",
    I => "Lipid transport and metabolism",
    J => "Translation",
    K => "Transcription",
    L => "Replication, recombination and repair",
    M => "Cell wall/membrane biogenesis",
    N => "Cell motility",
    O => "Posttranslational modification, protein turnover, chaperones",
    P => "Inorganic ion transport and metabolism",
    Q => "Secondary metabolites biosynthesis, transport and catabolism",
    R => "General function prediction only",
    S => "Function unknown",
    T => "Signal transduction mechanisms",
    U => "Intracellular trafficking and secretion",
    V => "Defense mechanisms", 
    W => "Extracellular structures", 
    Z => "Cytoskeleton", 
  '-' => "Not in COGs"
};

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
    -l                  Output file format is LaTeX [default=CSV]
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

C<perl distribute_by_cog.pl -i ../data/Mock\ Gene\ 1.txt -w GCCGTCTGAA -o table3.csv>

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

    my $thrownout = 0;
    my $ready;
    while(<$fh>) {
        if ($_ =~ /^Location/) {
            $ready = 1;
            next;
        }
        next unless($ready);        

        chop;

        my ($location, $direction, $strand, $length, $pid, $gene, $code, $cog, $product) = split(/\t/, $_);

        # next unless($cog =~ /A$/);

        my $sequence = getSequenceByGeneLocation(input    => $input, 
                                                 location => $location,
                                                 product  => $product);        
        my $e;
        if ($e = Exception::Class->caught('SequenceNotFoundException')) { 
            warn $e->error, "\n", $e->trace->as_string, "\n";
            Log::Log4perl::get_logger()->debug("Throwing one out");
            $thrownout++;
            next;
        }
        
        my $groups = parseTypesFromCog($cog);        
        if (scalar @{$groups} < 1) {
            push (@{$groups}, '-');
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
    }

    Log::Log4perl::get_logger()->debug("Threw out $thrownout sequences that couldn't be found.");
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
    my %params  = @_;
    my $input   = $params{input};
    my $product = $params{product};
    my $loc     = $params{location};

    my ($cog_start, $cog_stop) = split(/\.\./, $loc);
    
    my $new_location  = min($cog_start, $cog_stop) . '-' . max($cog_start, $cog_stop);
    my $comp_location = 'c' . max($cog_start, $cog_stop) . '-' . min($cog_start, $cog_stop);
        
    open(FFN, "<$input" . '.ffn') || die "Cannot open " . "<$input" . '.ffn';
    
    my $seq;
    while (<FFN>) {
        my $line = $_;
        
        if (($line =~ /^\>/)
            && (index($line, $new_location) > -1
                || index($line, $comp_location) > -1)
            && index($line, $product) > -1) { # Header

            $seq = $line;

            while (defined <FFN>) {
                $line = <FFN>;
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

    close(FFN);

    eval { SequenceNotFoundException->throw(error => "No sequence found for $product at location $new_location or $comp_location") } ;
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

    $cog =~ s/\s//g;

    # Log::Log4perl::get_logger()->debug("Getting COG Categories for $cog");
    
    $cog =~ s/COG[0-9]+//g;
    @retval = split(//,$cog);

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

    if ($params{format}) {
        printLatex(%params);
    }
    else {
        printCsv(%params);
    }
}

=head2 C<printLatex>

=pod 

Given hash of data, prints out values in a latex template

=head3 Parameters

=over

=item params 

=back

=cut
sub printLatex {
    my %params = @_;

    get_logger()->debug("Writing LaTeX to " . $params{file});
    my $fh = new FileHandle(">" . $params{file});

    print $fh <<EOF
\\documentclass[11pt,notitlepage]{article}
\\author{Leo Przybylski}
\\usepackage{graphicx}

\\begin{document}
{\\tiny
\%\\begin{tabular}{\@{} c \@{}}
\%  \\hline \\\\
  \\begin{tabular}{\@{} p{1cm} l p{1cm} p{1cm} p{1cm} p{1.5cm} \@{}}
    \\hline \\\\
     COG Groups & & No. of DUS& No. of CDS& Average CDS Length& Relative Abundance (95\\% CI)\\\\
\%  \\end{tabular}\\\\
    \\hline \\\\
\%  \\begin{tabular}{llrrrl}
EOF
;

    foreach my $group (@{$params{groups}}) {
        print $fh $group->{name} if ($group->{name});
        print $fh '&' . "\n";
        print $fh $group->{description} if ($group->{description});
        print $fh '&' . "\n";
        print $fh $group->{dus_count} if ($group->{dus_count});
        print $fh '&' . "\n";
        print $fh $group->{cds_count} if ($group->{cds_count});
        print $fh '&' . "\n";
        print $fh $group->{avg_cds} if ($group->{avg_cds});
        print $fh '&' . "\n";
        print $fh sprintf("%.2f", $group->{abundance}) if ($group->{abundance});
        print $fh "\n";
        print $fh '\\\\';
    }

print $fh <<EOF
    \\hline
  \\end{tabular}
\%  \\hline 
\%\\end{tabular}
}
\\end{document}
EOF
}

=head2 C<printCsv>

=pod 

Given hash of data, prints out values in a CSV template

=head3 Parameters

=over

=item params 

=back

=cut
sub printCsv {
    my %params = @_;

    get_logger()->debug("Writing CSV to " . $params{file});
    my $fh = new FileHandle(">" . $params{file});

    foreach my $group (@{$params{groups}}) {
        print $fh $group->{name} . "\t" if ($group->{name});
        print $fh $group->{description} . "\t" if ($group->{description});
        print $fh $group->{dus_count} . "\t" if ($group->{dus_count});
        print $fh $group->{cds_count} . "\t" if ($group->{cds_count});
        print $fh $group->{avg_cds} . "\t" if ($group->{avg_cds});
        print $fh sprintf("%.2f", $group->{abundance}) if ($group->{abundance});
        print $fh "\n";
    }
}

my $debug = 4;
my $input; 
my $output;
my $word;
my $latex;

GetOptions( 'help|?' => \$help,
                 man => \$man, 
           'debug=s' => \$debug,
        'o|output=s' => \$output,
          'w|word=s' => \$word,
                 'l' => \$latex,
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
my @type_data;
my $types = distribute($input);
push(@{$types}, "All");


foreach my $type (sort { $a cmp $b } @{$types}) {
    my %data;
    
    my $file = $type . '.ffn';
    if ($type eq 'All') {
        $file = $input . '.ffn';
    }

    my $stats = Fasta::load($file, 'GCCGTCTGAA');
    $data{name} = $type;
    $data{description} = $cog_desc_map->{$type};
    $data{dus_count} = $stats->{dus_size};
    $data{cds_count} = $stats->{cds_size};
    $data{avg_cds}   = $stats->{cds_avg_length};
    $data{abundance} = $stats->{abundance};
    push(@type_data, \%data);

    get_logger()->debug("CDS Size = " . $stats->{cds_size} . "\n");
    get_logger()->debug("DUS Size = " . $stats->{dus_size} . "\n");
    get_logger()->debug("CDS Avg Length = " . $stats->{cds_avg_length} . "\n");
    get_logger()->debug("Expected number = " . $stats->{expected}, "\n");
}

printTemplate(file => $output, groups => \@type_data, format => defined $latex);

foreach my $group (keys %{$cog_desc_map}) {
    my $file = "$group.ffn";
    unlink $file if (-e $file);
}

exit 0;
__END__
