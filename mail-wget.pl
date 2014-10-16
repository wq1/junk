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

use MIME::Base64 'encode_base64';
#use URI::Escape;
use Encode::Guess ('euc-jp', 'shiftjis', '7bit-jis');
use IPC::Open3;

use constant LOCALE => find_encoding('utf8');


sub main() {

  my (
    $sub, $from, $to,
    $contentType, $contentDisposition,
    $html64
  );

  $to   = 'foo@example.com';
  $from = 'bar@example.com';

  {
    my $html;

    {
      my (
        $wget, $wgetOut,
        $mime, $mimeIn, $mimeOut, $mimePid,
        $buf, $bs
      );

      $mime = "file -bi -";
      $mimePid = open3($mimeIn, $mimeOut, undef, LOCALE->encode($mime))
        || die($!);

      $wget = "wget -qO - '$ARGV[0]'";
      open($wgetOut, '-|:raw', LOCALE->encode($wget))
        || die($!);

      $bs = 60*57; # Optimized for Base64 Encoding (must be n*57 bytes)

      while (read($wgetOut, $buf, $bs)) {
        print($mimeIn $buf);
        $html   .= $buf;
        $html64 .= encode_base64($buf);
      }
      close($wgetOut);
      close($mimeIn);

      while (read($mimeOut, $buf, $bs)) {
        $contentType .= $buf;
      }
      close($mimeOut);

      waitpid($mimePid, 0);
    }

    $contentType = LOCALE->decode($contentType);
    chomp($contentType);
  # chomp($html64);

    if ($contentType =~ /(.*?);/) {
      my $fn;
      if ($1 eq 'text/html') {
        my ($htmlDecoder, $fn64);

        $htmlDecoder = guess_encoding($html);
        last unless ref($htmlDecoder);
        $html = $htmlDecoder->decode($html);

        if ($html =~ /<title.*?>\s*(.*?)\s*<\/title/si) {
          $fn   = "$1.html";
          $fn64 = '=?UTF-8?B?'.
                  encode_base64(encode_utf8($fn), '').
                  '?=';
          $sub  = '=?UTF-8?B?'.
                  encode_base64(encode_utf8($1), '').
                  '?=';

          $contentType  .= "; name=\"$fn64\"";
          $contentDisposition = "attachment; filename=\"$fn64\"";
        }
      }
      if ($fn eq '') {
        die();
      }
    } else {
      die();
    }
  }

  {
    my ($mail, $in);

    $mail = "sendmail -i '$to'";
    open($in, '|-:raw', LOCALE->encode($mail))
      || die($!);

    print($in "MIME-Version: 1.0", "\n");
    print($in "Subject: $sub", "\n");
    print($in "From: <$from>", "\n");
    print($in "To: <$to>", "\n");
    print($in "Content-Type: $contentType", "\n");
    print($in "Content-Disposition: $contentDisposition", "\n");
    print($in "Content-Transfer-Encoding: base64", "\n");
    print($in "\n");
    print($in "$html64");

    close($in);
  }

  return(0);

} exit(main());
