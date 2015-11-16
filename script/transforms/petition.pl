#!/usr/bin/perl -w
# Convert CSV to string for use in petition delivery.
# Expects data in the format <first_name>,<last_name>,<postcode>

if ($#ARGV < 0 ) {
  print "usage: petition <filename>\nWill write to <filename>.txt\n";
  exit;
}

open FILE, $ARGV[0]  or die $!;
open OUTFILE, ">$ARGV[0].txt" or die $!;

my @lines = <FILE>;
my $output = "";

foreach (@lines) {
  $_ =~ s/"//g;
  $_ =~ s/,/ /;
  $_ =~ s/\\N//;
  $_ =~ s/$/; /;
  $_ =~ s/\n//;
  $output = $output . $_
}

print OUTFILE $output;
close FILE;
close OUTFILE;
