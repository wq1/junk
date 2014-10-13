#! /usr/bin/perl

use strict;
use warnings;
use utf8;
use Encode;
use open (
  IN  => ':encoding(utf8)',
  OUT => ':utf8',
  ':std'
);
@ARGV = map { decode('utf8', $_) } @ARGV;

use MIME::Base64 ('encode_base64');

my($utf8, $cp932, $locale);
$utf8   = find_encoding('utf8');
$cp932  = find_encoding('cp932');
$locale = $utf8;


sub main() {

  my(
    $to, $from, $sub, $body,
    $contentType, $contentDisposition,
    $file, $name, $fn, $fh, $buf, $bs, $cmd
  );

  $to   = 'foo@example.com';
  $from = 'bar@example.com';

  $file = $ARGV[0];
  $name = _qx("ls '$file' | xargs -I{} basename {}");
  $fn   = '=?UTF-8?B?'.
          encode_base64(encode_utf8($name), '').
          '?=';
  $sub  = $fn;

  $contentType  = _qx("file -b --mime-type '$file'");
  $contentType .= "; name=\"$fn\"";
  $contentDisposition = "attachment; filename=\"$fn\"";

  open($fh, '<:raw', $file) or die "$!:$file";
  $bs = '4096';
  while (read($fh, $buf, $bs)) {
    $body .= $buf;
  }
  close($fh);
  $body = encode_base64($body);

  $cmd = "mail".
         " -aContent-Type:'$contentType'".
         " -aContent-Disposition:'$contentDisposition'".
         " -aContent-Transfer-Encoding:'base64'".
         " -s $sub".
         " -aFrom:$from $to";
  open($fh, '|-:raw', $cmd) or die "$!";
  print($fh $body);
  close($fh);

  return 0;
  
} exit(main());


sub _qx($) {

  my($cmd, $rtn);
  $cmd = _encode($locale, $_[0]);
  $rtn = qx($cmd);
  chomp($rtn);
  return($rtn);
  
}


sub _encode($$) {

  return($_[0]->encode($_[1]));
  
}