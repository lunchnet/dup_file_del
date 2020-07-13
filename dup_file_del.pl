#!perl
use 5.026;
use utf8;
use warnings;
use strict;
use open qw(:std :utf8);
#open my $infile, "<","NCRdata.csv" or die "open failed:$!";
use feature qw(signatures);
no warnings qw(experimental::signatures);
#no feature qw(indirect);
use List::Util qw(any all sum);
use Benchmark qw(timethese cmpthese);
#timethese(100000, { a => 'summ(100)', b => 'sum 1..100' });
#cmpthese(-5, { a => 'summ(100)', b => 'sum 1..100' });
#say "True" if any { $_ eq "hi" } qw/hi there test world/;
use Cwd;
#getcwd();

#push @INC, getcwd();
#require "dup_file_funcs.pm";

open my $infile, "<","dup_report.txt" or die "open failed:$!";

while (<$infile>){
    #Look for a plus sign in front of line; if found delete the file
    #specified by the rest of the line.
    chomp;
    if (/^\+\s*(.*$)/) {
	say "deleting: ".$1;
	#unlink $1;
    }
}
