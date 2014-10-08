#!/usr/bin/perl

my $fn = "$ARGV[0]";
open(file, "<$fn") or die("Error: $! $ARGV[0]");
my @data = <file>;
close (file);
open(file, ">$fn") or die("Error: $!");

my $a = "<body>";
my $b = "</body>";
my $c = "^    <script ";
my $d = "^    </footer>";

for (@data) {
  if (/$a/ .. /$b/) {
    if      (/$a/) {
      print file $_;
      print file "    <div id=\"wrapper\">\n";
    } elsif (/$d/) {
      $_=~ s/^/  /g;
      print file $_;
      print file "    <!-- /#wrapper --></div>\n";
    } elsif (!/$b/ && !/$c/) {
      $_=~ s/^/  /g;
      print file $_;
    } else {
      print file $_;
    }
  } else {
    print file $_;
  }
}

close (file);
