#!/usr/bin/perl

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

use feature 'state';
use MIME::Base64 'encode_base64';


sub _qx($);


sub main() {

  my (
    $file, $name, $fn, $in, $out, $buf, $bs, $cmd,
    $to, $from, $sub, $body,
    $contentType, $contentDisposition
  );
  $to   = 'foo@example.com';
  $from = 'bar@example.com';

  $file = $ARGV[0];
  $name = _qx("ls '$file' | xargs -I{} basename {}");
  $fn   = '=?UTF-8?B?'.
          encode_base64(encode_utf8($name), '').
          '?=';
  $sub  = $fn;

  $contentType  = _qx("file -bi '$file'").
                  "; name=\"$fn\"";
  $contentDisposition = "attachment; filename=\"$fn\"";

  $cmd = "mail".
         " -aContent-Type:'$contentType'".
         " -aContent-Disposition:'$contentDisposition'".
         " -aContent-Transfer-Encoding:'base64'".
         " -s $sub".
         " -aFrom:$from $to";
  $cmd = encode('utf8', $cmd);

  open($in, '<:raw', $file)  or die("$!:$file");
  open($out, '|-:raw', $cmd) or die("$!");
  $bs = 57*71; # 57bytes*71 < 4096
  while (read($in, $buf, $bs)) {
    $buf = encode_base64($buf);
    print($out $buf);
  }
  close($out);
  close($in);

  return(0);
  
} exit(main());


sub _qx($) {

  state $locale = find_encoding('utf8');

  my ($cmd, $rtn);
  $cmd = $locale->encode($_[0]);
  $rtn = qx($cmd);
  chomp($rtn);
  return($rtn);
  
}
