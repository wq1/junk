#!perl

use strict;
use warnings;
use utf8;
use Encode;
use open (
  IN  => ':encoding(cp932)',
  OUT => ':encoding(cp932)',
  ':std'
);
@ARGV = map { decode('cp932', $_) } @ARGV;

use feature 'state';


sub _qx($);


sub main() {

  print(_qx('echo あ'), "\n");
  return(0);

} exit(main());


sub _qx($) {

  state $locale = find_encoding('cp932');
  state $bs     = 4096;
 
  my($cmd, $rtn, $fh, $buf);
  $cmd = $locale->encode($_[0]);

  open($fh, '-|', $cmd) or die("$!");
  while (read($fh, $buf, $bs)) {
    $rtn .= $buf;
  }
  close($fh);

  chomp($rtn);
  return($rtn);
 
}
