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
import Log::Log4perl qw(:easy);

package IPIG;

=head1 Class C<Fasta>

=head2 Description 

Module for function programming style api to statistical information on FASTA 
formatted files.

=head3 Author: I<Leo Przybylski (przybyls@arizona.edu)>

=head1 Functions

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

=head2 complementWord

Reverses the given string. While iterating, applies a function to the each
character to reverse it as a WORD character.

=head3 Parameters

=over

=item C<word>  - DNA Uptake Sequence to reverse


=back

=head3 Returns

A fully reversed WORD String

=cut
sub complementWord {
    my $word = shift;

    return reverseWord($word,   # Reversed WORD
                sub { # Anonymous function for reversing characters
                    my $retval = shift;
                    $retval =~ tr/ACGT/TGCA/;
                    return $retval;
                       });
}

=head2 readingFrame

Get the full reading frame from a protein. 

=head3 Parameters

=over

=item C<protein>  - Protein CDS

=item C<frame>    - The frame to get

=back

=head3 Returns

The sequence of the reading frame

=cut
sub readingFrame {
    my $protein = shift;
    my $frame   = shift;
    
    my $retval = '';

    if ($frame > 3 || $frame < 1) {
        get_logger()->warn("Got a bad reading frame request $frame. Using 1.");
        $frame = 1;
    }

    my @protein = $protein =~ m/.{0,3}/g;
    foreach my $codon (@protein) {
        my @codon = split(//, $codon);
        $retval .= $codon[$frame - 1];
    }

    return $retval;
}

1;
