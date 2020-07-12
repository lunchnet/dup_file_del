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
use Benchmark qw(timethese cmpthese);
#timethese(100000, { a => 'summ(100)', b => 'sum 1..100' });
#cmpthese(-5, { a => 'summ(100)', b => 'sum 1..100' });
#say "True" if any { $_ eq "hi" } qw/hi there test world/;
use Cwd;

#Program to walk the given directory and remove duplicate files.
#Duplicates are determined by checksumming each file.
#use File::Checksum;
use File::Find;
use File::Basename;
use Digest::SHA;
use Data::Dumper;

#say Checksum("dup_file_del.pl",64*1024);
#say getcwd();
#chdir 'C:/' or die "Cannot change directory: $!";
#say getcwd();

#say "*************";
my %bighash;
my %sizes;
my $sha = Digest::SHA->new("256");
my @directories = getcwd();

# my $filename = "dup_file_del.pl";
# $sha->addfile($filename,"b");
# say $sha->hexdigest;

sub wanted {
    return if -d; #ignore directories
    return if $File::Find::name =~ m/^\./; #ignore hidden files
    $sha->new();
    #say "Inside wanted, filename is: $File::Find::name";
    $sha->addfile($File::Find::name,"b");
    my $hex = $sha->hexdigest;
    push @{$bighash{$hex}},$File::Find::name; 
    #    $bighash{$File::Find::name}=$sha->hexdigest;
    $sizes{$hex} = -s;
}

find(\&wanted, @directories);

#print Dumper(\%bighash);

#create hash of full filenames and checksums
#sort by checksum
#iterate and remove most deeply nested duplicates

#my %test = (test1 => 1, test2 => 2, test3 => 3, test4 => 4);
#my @sortedkv = map { $_,$bighash{$_} } sort keys %bighash;
#say map {$_.' '.$bighash{$_}."\n"} @sortedkeys;
#my @pairs = pairs @sortedkv;

#%bighash = unpairs grep { scalar @{$_->[1]} >= 2 } pairs %bighash;

my @todelete;
my @tokeep;
my $todeletesize = 0;

while (my ($key, $value) = each %bighash){
    #say $key, @$value;
    if (scalar @$value >= 2){ #there are duplicates
	#keep the file with the shorter full filename (including path)
	my @names = sort { length $a <=> length $b } @$value;
	push @tokeep, shift @names, $key;
	push @todelete, @names, $key;
	$todeletesize += $sizes{$key} * scalar @names;
    }    
}

open my $reportfile, ">","dup_report.txt" or die "open failed:$!";

say $reportfile "Files to keep:";
say $reportfile map {$_."\n"} @tokeep;
say $reportfile "Duplicate files to delete:";
say $reportfile map {$_."\n"} @todelete;
say ""; #$todeletesize = $todeletesize/(1024**2);
say $reportfile "Can free up to: $todeletesize bytes";

#Idea: have the user put a plus sign at the start of any line of the
#name of the file they wish to delete. Write a second script that goes
#through the dup_report.txt file and deletes all files with a plus
#sign in front. It should warn if asking to delete all the files or
#not all of them.

#have a command line option to have a minimum size file that gets
#listed.

#sort the output by filesize. It is about saving disk space afterall.

#some code here about odering by size...
