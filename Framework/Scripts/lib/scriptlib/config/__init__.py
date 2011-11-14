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

import optparse
import os

class OptionParser(optparse.OptionParser):
  def parse_config(self):
    b = 'the project base directory, '\
        'can be relative to the working directory, '\
        'default value: $PROJECT_DIR'
    r = 'the location for resources, '\
        'can be relative to the working directory, '\
        'default value: #base/Resources'
    s = 'the location for source code, '\
        'can be relative to the working directory, '\
        'default value: #base/Source'
    l = 'the base language, '\
        'default value: $BASE_LANGUAGE if defined, else "en"'
    t = 'the location for temporary (scratch) files, '\
        'can be relative to the working directory, '\
        'default value: $CONFIGURATION_TEMP_DIR'
    p = 'interface builder plugin directory. '\
        'default value: $IBC_PLUGIN_SEARCH_PATHS'
    self.add_option('-b', '--base', dest='base', default=None, help=b)
    self.add_option('-r', '--resources', dest='resources', default=None, help=r)
    self.add_option('-s', '--source', dest='source', default=None, help=s)
    self.add_option('-l', '--lang', dest='lang', default=None, help=l)
    self.add_option('-t', '--tempdir', dest='tempdir', default=None, help=t)
    self.add_option('-p', '--plugindir', dest='plugin', default=None, help=p)

    options, args = self.parse_args()
    
    self.remove_option('-b')
    self.remove_option('-r')
    self.remove_option('-s')
    self.remove_option('-l')
    self.remove_option('-t')
    self.remove_option('-p')
    
    base = options.base or os.environ.get('PROJECT_DIR', '.')
    
    return Config(
      resources=options.resources or os.path.join(base, 'Resources'),
      source=options.source or os.path.join(base, 'Source'),
      lang=options.lang or os.environ.get('BASE_LANGUAGE', 'en'),
      tempdir=options.tempdir or os.environ.get('CONFIGURATION_TEMP_DIR'),
      plugindir=options.plugin or os.environ.get('IBC_PLUGIN_SEARCH_PATHS')), options, args

class Config(object):
  def __init__(self, **options):
    self.resources = options.get('resources')
    self.source = options.get('source')
    self.lang = options.get('lang')
    self.tempdir = options.get('tempdir')
    self.plugindir = options.get('plugindir')
