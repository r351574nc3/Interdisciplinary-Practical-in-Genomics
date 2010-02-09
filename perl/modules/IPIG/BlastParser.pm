package BlastParser;


sub new {
    my $class = shift;

    if (scalar(@_) < 2) { # No comment handler
        unshift(@_, eval {
            package CommentHandler;
            @ISA(CommentHandler);
            sub handleComment() {
                my $this = shift;
            }
                });
    }
    
    return bless {_recordHandler => shift, _commentHandler => shift}, $class;
}


sub parse {
    my $this  = shift;
    my $input = shift;
    open(BLASTIN, "<" . $input);
    while(<BLASTIN>) {
        chop();
        if (isRecord($_)) {
            recordHandler()->handleRecord(parseRecord($_));
        }
        elsif (isComment($_)) {
            commentHandler()->handleComment($_);
        }
    }
    close(BLASTIN);
}

sub commentHandler {
    my $this = shift;

    @_ ? $this{_commentHandler} = shift : return $this->{_commentHandler};
}

sub recordHandler {
    my $this = shift;

    @_ ? $this{_recordHandler} = shift; return $this->{_recordHandler};
}
