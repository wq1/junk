#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Encode;
use open (
  IN  => ':encoding(utf8)',
  OUT => ':utf8',
  ':std',
);
@ARGV = map { decode('utf8', $_); } @ARGV;

use MIME::Base64 'encode_base64';
use File::Basename;

sub _qx($);

use constant LOCALE => find_encoding('utf8');


sub main() {

  my (
    $file, $sub, $from, $to,
    $contentType, $contentDisposition,
  );

  $to   = 'foo@example.com';
  $from = 'bar@example.com';

  {
    my ($fn, $fn64);

    $file = $ARGV[0];
    $fn   = basename($ARGV[0]);

    $fn64 = '=?UTF-8?B?'.
            encode_base64(encode_utf8($fn), '').
            '?='.
            '';
    $sub  = $fn64;

    $contentType  = _qx("file -bi '$file'").
                    "; name=\"$fn64\"".
                    '';
    $contentDisposition = "attachment; filename=\"$fn64\"";
  }

  {
    my ($head, $mail, $in, $out, $buf, $bs);

    $head = "MIME-Version: 1.0\n".
            "Subject: $sub\n".
            "From: <$from>\n".
            "To: <$to>\n".
            "Content-Type: $contentType\n".
            "Content-Disposition: $contentDisposition\n".
            "Content-Transfer-Encoding: base64\n".
            '';

    $mail = "sendmail -itf '$from'";

    open($out, '<:raw', $file)
      || die($!);
    open($in, '|-:raw', LOCALE->encode($mail))
      || die($!);

    print($in encode('us-ascii', $head));

    $bs = 60*57; # Optimized for Base64 Encoding (must be n*57 bytes)
    while (read($out, $buf, $bs)) {
      $buf = encode_base64($buf);
      print($in $buf);
    }

    close($in);
    close($out);
  }

  return(0);

} exit(main());


sub _qx($) {

  my ($cmd, $rtn);
  $cmd = LOCALE->encode($_[0]);
  $rtn = qx($cmd);
  chomp($rtn);
  return($rtn);

}
