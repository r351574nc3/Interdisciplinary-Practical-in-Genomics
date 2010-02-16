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
package IPIG::BlastParser;

=head1 Class C<BlastParser>

=cut

=head2 Description 

=pod 

Class mainly responsible for parsing blast input into C<BlastRecord> instances. 

=head3 Author: I<Leo Przybylski (przybyls@arizona.edu)>

=cut

use strict;
use warnings;

BEGIN {
    require "CommentHandler.pm";
    import IPIG::CommentHandler;
    require "Edge.pm";
    import IPIG::Edge;
}


=head2 Default Constructor

=pod 

Constructs the C<BlastParser> from its attributes. A C<RecordHandler> is
required. If the C<CommentHandler> is not provided, a default is used.

=head3 Parameters

=over

=item C<rh> - a C<RecordHandler> instance

=item C<ch> - a C<CommentHandler> instance

=back

=cut
sub new {
    my $class = shift;
    my $rh = shift;
    my $ch = shift;

    unless ($ch) { # No comment handler
        $ch = eval {
            package AnonCommentHandler;
            our @ISA = (qw/IPIG::CommentHandler/);

            sub handleComment {
                my $this = shift;
            }
            __PACKAGE__;
        }->new();
    }

    return bless {_recordHandler => $rh, _commentHandler => $ch}, $class;
}


=head2 Method C<parse>

=pod 

Opens the file directed by the provided filename and parses it into C<BlastRecord> instances.
It then passes the C<BlastRecord> instances to the C<RecordHandler>

=head3 Parameters

=over

=item C<input> - path of the file to parse

=back

=cut
sub parse {
    my $this  = shift;
    my $input = shift;
    print "Opening $input\n";
    
    open(BLASTIN, "<" . $input);
    while(<BLASTIN>) {
        chop();
        if ($this->isRecord($_)) {
            my $alignment = 0;
            my $record = $this->recordHandler()->handleRecord($this->parseRecord($_));
            
            if ($record->isSelfHit()) {
                $this->recordHandler()->selfHit($record);
            }
            else {
                $this->recordHandler()->validateRecord($record);
            }
        }
        elsif ($this->isComment($_)) {
            $this->commentHandler()->handleComment();
        }
    }
    close(BLASTIN);
}

=head2 Method C<parseRecord>

=pod 

Takes a line from the blast output file and parses it into an array of fields

=head3 Parameters

=over

=item a record from the blast output file

=back

=cut
sub parseRecord {
    my $this = shift;
    return split(/\t/, shift);
}

=head2 Method C<isRecord>

=pod 

Determines if the given line is indeed a record. If it's not a record, it's probably
a comment

=head3 Parameters

=over

=item a record from the blast output file

=back

=cut
sub isRecord {
    my $this   = shift;
    my $record = shift;
    return $record !~ /^#/? 1 : 0;
}

=head2 Method C<isComment>

=pod 

Determines if the given line is indeed a comment. If it's not a comment, it's probably
a record

=head3 Parameters

=over

=item a record from the blast output file

=back

=cut
sub isComment {
    my $this   = shift;
    my $record = shift;
    return !$this->isRecord($record)
}

=head2 Getter/Setter C<commentHandler>

=pod 

Getter/Setter for the commentHandler

=head3 Parameters

=over

=item C<commentHandler> to set (optional)

=back

=head3 Returns

=pod 

Gets the C<commentHandler>. Only returns something if there is no parameter present.

=cut
sub commentHandler {
    my $this = shift;

    @_ ? $this->{_commentHandler} = shift : return $this->{_commentHandler};
}

=head2 Getter/Setter C<recordHandler>

=pod 

Getter/Setter for the recordHandler

=head3 Parameters

=over

=item C<recordHandler> to set (optional)

=back

=head3 Returns

=pod 

Gets the C<recordHandler>. Only returns something if there is no parameter present.

=cut
sub recordHandler {
    my $this = shift;

    @_ ? $this->{_recordHandler} = shift : return $this->{_recordHandler};
}

return 1;