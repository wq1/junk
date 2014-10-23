#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys;
import re;
import tempfile;
import pathlib;
# import base64;
# import shlex;
# import subprocess;
# import html.parser;
# import chardet;


def main():
  to = 'foo@example.com';
  fr = 'bar@example.com';

  match = re.match(r'http://|https://', sys.argv[1], re.I);
  if match:
    http = 1;
    src = tempfile.TemporaryFile();

    src.seek(0);
    wget = MyPopen(
      'wget -qO - {}'.format(sys.argv[1]),
      stdout = src,
    );
    wget.exe();
  else:
    http = 0;
    src = open(sys.argv[1], 'rb');

  src.seek(0);
  mime = MyPopen(
    'file -bi -',
    stdin = src,
  );
  contType = mime.exe();
  contType = contType.decode().rstrip();

  match = re.match(r'text/html', contType);
  if match:
    src.seek(0);
    html00 = src.read();
    html00 = autodec(html00);
    title = GetTag();
    title = title.get(html00, 'title');

    fn  = '{}.html'.format(title);
    sub = title;
  else:
    if http:
      fn = pathlib.PurePosixPath(sys.argv[1]).name;
    else:
      fn = pathlib.PurePath(sys.argv[1]).name;
    sub = fn;

  fn  = b64utf8(fn);
  sub = b64utf8(sub);
  contType += '; name=\"{}\"'.format(fn);
  contDispos = 'attachment; filename=\"{}\"'.format(fn);

  head  = 'MIME-Version: 1.0\n';
  head += 'Subject: {}\n'.format(sub);
  head += 'From: <{}>\n' .format(fr);
  head += 'To: <{}>\n'   .format(to);
  head += 'Content-Type: {}\n'       .format(contType);
  head += 'Content-Disposition: {}\n'.format(contDispos);
  head += 'Content-Transfer-Encoding: base64\n';

  mail = MyPopen(
    'sendmail -itf {}'.format(fr),
    stdout = None,
    stderr = None,
  );
  mail.stdin.write(head.encode());

  src.seek(0);
  while True:
    buf = src.read(60*57); # Optimized for Base64 Encoding (must be n*57 bytes)
    if not buf:
      break;
    mail.stdin.write(b64eol(buf));

  mail.stdin.close();
  mail.exe();

  return 0;


import shlex;
import subprocess;
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


import html.parser;
class GetTag(html.parser.HTMLParser):
  def feed(self, data, tag):
    self.tgt   = tag;
    self.isTgt = 0;
    self.rtn   = [];
    html.parser.HTMLParser.feed(self, data);

  def handle_starttag(self, tag, attrs):
    if tag == self.tgt:
      self.isTgt = 1;

  def handle_data(self, data):
    if self.isTgt:
      self.isTgt = 0;
      self.rtn.append(data);

  def get(self, data, tag):
    self.feed(data, tag);
    return self.rtn[-1];

  def getArray(self, data, tag):
    self.feed(data, tag);
    return self.rtn;


import chardet;
def autodec(s, errors='ignore'):
  s = s.decode(chardet.detect(s)['encoding'], errors);
  return s;


import base64;

def b64utf8(s):
  s = '=?UTF-8?B?{}?='.format(base64.b64encode(s.encode()).decode());
  return s;

def b64eol(s, length=76):
  buf = base64.b64encode(s);
  s = [];
  for i in range(0, len(buf), length):
    s.append(buf[i:i+length]);
  s.append(b'');
  s = b'\n'.join(s);
  return s;


if __name__ == '__main__':
  sys.exit(main());
