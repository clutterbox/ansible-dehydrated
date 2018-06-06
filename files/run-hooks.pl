#!/usr/bin/perl
#
# This script is a wrapper to have multiple hooks with
# the dehydrated Let's Encrypt client
#
# Usage:
# ./dehydated --hook ./dehydated-hooks.pl [other dehydrated options]
# alternative via config
# HOOK=/path/to/dehydrated-hooks.pl
#
# Remember: run-parts has certain constranints on filenames
# Filenames must match ^[a-zA-Z0-9_\-]+$

use strict;
use warnings;

my $hooks = "/etc/dehydrated/hooks.d";

opendir(my $dh, $hooks);
my @list = sort map { "$hooks/$_"; } grep { /^[0-9a-zA-Z-_]/ } readdir($dh);

foreach (@list) {
        print " ++ running hook $_\n";
        system($_, @ARGV);
}
