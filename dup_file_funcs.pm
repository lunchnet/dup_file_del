package dup_file_funcs;
use feature qw(signatures);
no warnings qw(experimental::signatures);

sub metric_size ($size){
#    print "size is",$size,"\n";
    my $len = length $size;
#    print "len is", $len, "\n";
    if ($len > 12) { return int($size/10**12)." TB";}
    elsif ($len > 9) { return int($size/10**9)." GB";}
    elsif ($len > 6) { return int($size/10**6)." MB";}
    elsif ($len > 3) { return int($size/10**3)." KB";}
    else { return $size." Bytes";}
}

1;
