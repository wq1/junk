#!perl

use strict;
use warnings;
use utf8;
use Encode;
use open (
  IN  => ':encoding(cp932)',
  OUT => ':encoding(cp932)',
  ':std',
);
@ARGV = map { decode('cp932', $_) } @ARGV;

sub _qx($);

use constant LOCALE => find_encoding('cp932');


sub main() {

  print(_qx('echo あ'), "\n");
  return(0);

} exit(main());


sub _qx($) {

  my (
    $cmd, $rtn,
    $fh, $buf, $bs,
  );

  $cmd = LOCALE->encode($_[0]);

  open($fh, '-|', $cmd)
    || die($!);
  $bs = 4096;
  while (read($fh, $buf, $bs)) {
    $rtn .= $buf;
  }
  close($fh);

  chomp($rtn);
  return($rtn);
 
}
