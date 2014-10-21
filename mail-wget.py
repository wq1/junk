#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys;
import shlex;
import subprocess;
import base64;
import tempfile;
import re;
import html.parser;
import chardet;


class MyPopen(subprocess.Popen):
  def __init__(
    self, args,
    stdin  = subprocess.PIPE,
    stdout = subprocess.PIPE,
    stderr = subprocess.PIPE,
  ):
    args = shlex.split(args);
    subprocess.Popen.__init__(
      self, args,
      stdin  = stdin,
      stdout = stdout,
      stderr = stderr,
    );

  def exe(self, input=None):
    stdout = self.communicate(input)[0];
    return stdout;


class GetTag(html.parser.HTMLParser):
  def feed(self, data, tag):
    self.tgt   = tag;
    self.isTgt = 0;
    self.rtn   = [];
    html.parser.HTMLParser.feed(self, data);

  def handle_starttag(self, tag, attrs):
    if (tag == self.tgt):
      self.isTgt = 1;

  def handle_data(self, data):
    if (self.isTgt):
      self.isTgt = 0;
      self.rtn.append(data);

  def get(self, data, tag):
    self.feed(data, tag);
    return (self.rtn[-1]);

  def getArray(self, data, tag):
    self.feed(data, tag);
    return (self.rtn);


def main():
  to = 'foo@example.com';
  fr = 'bar@example.com';

  tmp = tempfile.TemporaryFile();

  tmp.seek(0);
  wget = MyPopen(
    'wget -qO - {}'.format(sys.argv[1]),
    stdout = tmp,
  );
  wget.exe();

  tmp.seek(0);
  mime = MyPopen(
    'file -bi -',
    stdin = tmp,
  );
  contType = mime.exe();

  contType = contType.decode().rstrip();
  match = re.match(r'text/html', contType);

  if (match):
    html00 = [];
    html64 = [];

    tmp.seek(0);
    while True:
      buf = tmp.read(57); # Optimized for Base64 Encoding
      if (not buf):
        break;
      html00.append(buf);
      html64.append(base64.b64encode(buf));
    html00 = b''  .join(html00);
    html64 = b'\n'.join(html64);

    html00 = html00.decode(chardet.detect(html00)['encoding'], 'ignore').rstrip();
  # html64 = html64.decode().rstrip();
    title = GetTag();
    title = title.get(html00, 'title');

    sub64 = '=?UTF-8?B?{}?='.format(base64.b64encode(title.encode()).decode());
    fn00 = '{}.html'.format(title);
    fn64 = '=?UTF-8?B?{}?='.format(base64.b64encode(fn00.encode()).decode());
    contType = '{}; name=\"{}\"'.format(contType, fn64);
    contDispos = 'attachment; filename=\"{}\"'.format(fn64);
  else:
    sys.exit();

  head  = 'MIME-Version: 1.0\n'
  head += 'Subject: {}\n'.format(sub64)
  head += 'From: <{}>\n' .format(fr)
  head += 'To: <{}>\n'   .format(to)
  head += 'Content-Type: {}\n'       .format(contType)
  head += 'Content-Disposition: {}\n'.format(contDispos)
  head += 'Content-Transfer-Encoding: base64\n'
  head  = head.encode();

  mail = MyPopen(
    'sendmail -itf {}'.format(fr),
  );
  mail.exe(input = head + html64);

  return 0;


if (__name__ == '__main__'):
  main();
