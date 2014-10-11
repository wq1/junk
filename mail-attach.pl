#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use open IN  => ':encoding(utf8)';
use open OUT => ':utf8';
use open ':std';

use Encode       qw(encode_utf8);
use MIME::Base64 qw(encode_base64);

my($to, $from, $file, $name, $sub, $fn, $fh, $buf, $bs, $body,
   $contentType, $contentDisposition);

$to   = 'foo@example.com';
$from = 'bar@example.com';
$file = $ARGV[0];
$name = qx(ls '$file' | xargs -I{} basename {}); chomp($name);

$fn   = '=?UTF-8?B?'.
        encode_base64(encode_utf8($name), '').
        '?=';
$sub  = $fn;

$contentType  = qx(file -b --mime-type '$file'); chomp($contentType);
$contentType .= "; name=\"$fn\"";
$contentDisposition = "attachment; filename=\"$fn\"";

open($fh, '<:raw', $file) or die "$!:$file";
$bs = '4096';
while (read($fh, $buf, $bs)) {
  $body .= $buf;
}
close($fh);

$body = encode_base64($body); chomp($body);

open($fh, '|-:raw', "mail -aContent-Type:'$contentType' -aContent-Disposition:'$contentDisposition' -aContent-Transfer-Encoding:'base64' -s $sub -aFrom:$from $to")
 or die "$!";
print($fh $body);
close($fh);

exit;
