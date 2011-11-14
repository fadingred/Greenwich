# 
# Copyright (c) 2011 FadingRed LLC
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
# documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
# Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
# WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# 

from util import *
from hashlib import md5
import codecs
import sys
import os

class Xib(object):
  def __init__(self, name, config):
    self.name = clean_name(name)
    self.config = config
    self._mtime = None
    self._gtime = None
  
  def path(self):
    resources = self.config.resources
    path = os.path.join(resources, '%s.xib' % self.name)
    return path
  
  def modification_time(self):
    if self._mtime == None:
      try: self._mtime = os.path.getmtime(self.path())
      except OSError: self._mtime = 0
    return self._mtime
  
  def _generation(self):
    tempdir = self.config.tempdir
    gendir = os.path.join(tempdir, 'strings_generation')
    path = os.path.join(gendir, '%s-%s.time' % (self.name, md5(self.path()).hexdigest()))
    return path
  
  def generation_time(self):
    if self._gtime == None:
      try: self._gtime = os.path.getmtime(self._generation())
      except OSError: self._gtime = 0
    return self._gtime
  
  def _ensure_dir_for_file(self, path):
    directory = os.path.dirname(path)
    if not os.path.exists(directory):
      os.mkdir(directory)
  
  def generate(self, strings):
    """
    Generate strings file in an expected format and update generation time
    """
    strings.ensure_dir()
    result = os.system('ibtool --plugin-dir "%s" --generate-strings-file "%s" "%s"' % (
      self.config.plugindir, strings.path(), self.path()))
    if result != 0:
      sys.stderr.write('warning: error generating strings, see prior output for information\n');
    strings.normalize()
    generation = self._generation()
    self._ensure_dir_for_file(generation)
    os.system('touch "%s"' % (generation,))
    self._gtime = None
