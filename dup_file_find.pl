#!perl
use 5.026;
use utf8;
use warnings;
use strict;
use open qw(:std :utf8);
#open my $reportfile, ">","dup_report.txt" or die "open failed:$!";
use feature qw(signatures);
no warnings qw(experimental::signatures);
#no feature qw(indirect);
use List::Util qw(any all sum pairs unpairs);
#say "True" if any { $_ eq "hi" } qw/hi there test world/;
use Benchmark qw(timethese cmpthese);
#timethese(100000, { a => 'summ(100)', b => 'sum 1..100' });
#cmpthese(-5, { a => 'summ(100)', b => 'sum 1..100' });
use Cwd;
#getcwd();

#Program to walk the given directory and remove duplicate files.
#Duplicates are determined by checksumming each file.

use File::Find;
use Digest::SHA;

push @INC, getcwd();
require "dup_file_funcs.pm";

my %bighash;
my %sizes;
my $sha = Digest::SHA->new("256");
my @directories = getcwd();

sub wanted {
    return if -d; #ignore directories
    return if $File::Find::name =~ m/^\./; #ignore hidden files
    #say "Inside wanted, filename is: $File::Find::name";
    $sha->new();
    $sha->addfile($File::Find::name,"b");
    my $hex = $sha->hexdigest;
    push @{$bighash{$hex}},$File::Find::name; 
    $sizes{$hex} = -s;
}

#Runs too slowly, apparently opening and reading multiple files is
#expensive. Can try MCE multicore, perl interpreter threads, or
#calling an external shasum executable.
find(\&wanted, @directories); 

my @keysbysize = sort { $sizes{$b} <=> $sizes{$a} } keys %sizes;
my $todeletesize = 0; #total size of duplicate files
my $numduplicates=0; #how many duplicate files are there

#Prepare data for output
foreach my $key (@keysbysize){
    my $value = $bighash{$key};
    if (scalar @$value >= 2){ #there are duplicates
	my @names = sort { length $a <=> length $b } @$value;
	$bighash{$key} = \@names;
	$todeletesize += $sizes{$key} * (scalar @names - 1);
	$numduplicates += scalar @names - 1;
    }
}

#Write data to output file
open my $reportfile, ">","dup_report.txt" or die "open failed:$!";
foreach my $key (@keysbysize){
    my $value = $bighash{$key};
    if (scalar @$value >= 2){ #there are duplicates
	say $reportfile '*'x80;
	say $reportfile $key, "\t", dup_file_funcs::metric_size($sizes{$key});
	print $reportfile map { "\t".$_."\n" } @{$bighash{$key}};
    }	
}
print "\n";
say $reportfile '*'x80;
say $reportfile "Can free up to: ",
    dup_file_funcs::metric_size($todeletesize), " in $numduplicates files.";

#EOF
