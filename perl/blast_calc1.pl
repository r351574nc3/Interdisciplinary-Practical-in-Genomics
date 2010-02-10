#!/usr/bin/perl

use strict;
use lib 'modules/IPIG';

BEGIN {
    require "BlastParser.class";
    import BlastParser;
    require "BlastRecordHandler.class";
    import BlastRecordHandler;
}



package Main;

use strict;

use warnings;

use base 'Exporter';

our @EXPORT = qw(main);

sub new {
    my $class = shift;
    return bless {}, $class;
}

sub main {
    my $parser = new BlastParser(new BlastRecordHandler());
    $parser->parse(pop(@ARGV));
}

Main::main();
