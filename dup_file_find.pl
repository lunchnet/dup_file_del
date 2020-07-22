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

my %bighash; #Store lists of identical files keyed by their checksum.
my %sizes; #Store sizes of each file keyed by checksum.
my $sha = Digest::SHA->new("256");
my @directories = getcwd();

sub wanted {
    return if -d; #Ignore directories.
    return if $File::Find::name =~ m/^\./; #Ignore hidden files.
    #say "Inside wanted, filename is: $File::Find::name";
    $sha->new();
    $sha->addfile($File::Find::name,"b");
    my $hex = $sha->hexdigest;
    push @{$bighash{$hex}},$File::Find::name; 
    $sizes{$hex} = -s;
}

#Written like this, the program is very slow. Apparently opening
#and reading multiple files is too expensive. Can try MCE multicore,
#perl interpreter threads, or calling an external shasum executable.
find(\&wanted, @directories); 

my @keysbysize = sort { $sizes{$b} <=> $sizes{$a} } keys %sizes;
my $todeletesize = 0; #Total bytes in duplicate files.
my $numduplicates=0; #Number of duplicate files.

#Prepare data for output: sort duplicate file names by length,
#calculate total bytes we can delete, and calculate total number of
#duplicate files.
foreach my $key (@keysbysize){
    my $names = $bighash{$key};
    next unless @$names >= 2; #there are duplicates
    @$names = sort { length $a <=> length $b } @$names;
    $todeletesize += $sizes{$key} * (@$names - 1);
    $numduplicates += @$names - 1;
}

#Write data to output file. From the largest to the smallest files,
#print the hash and filesize on one line, and all duplicate files
#underneath. Finally, print the total bytes we can delete and the
#number of duplicate files.
open my $reportfile, ">","dup_report.txt" or die "open failed:$!";
foreach my $key (@keysbysize){
    my $names = $bighash{$key};
    next unless @$names >= 2; #there are duplicates
    say $reportfile '*'x80;
    say $reportfile $key, "\t", dup_file_funcs::metric_size($sizes{$key});
    print $reportfile map { "\t".$_."\n" } @$names;
}
print "\n";
say $reportfile '*'x80;
say $reportfile "Can free up to: ",
    dup_file_funcs::metric_size($todeletesize), " in $numduplicates files.";

#EOF
