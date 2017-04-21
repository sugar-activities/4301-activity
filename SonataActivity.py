"""Sonata is a simple GTK+ client for the Music Player Daemon.
"""

__author__ = "Scott Horowitz"
__email__ = "stonecrest@gmail.com"
__license__ = """
Sonata, a simple GTK+ client for the Music Player Daemon
Copyright 2006 Scott Horowitz <stonecrest@gmail.com>
OLPC version by Owen Williams <owen@ywwg.com>

This file is part of Sonata.

Sonata is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

Sonata is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Sonata; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
"""

import logging
import sys, os, os.path
import subprocess

from sugar.activity import activity
from sugar import env

import sonata

HAVE_DBUS = False

#where are we?
activity_root = activity.get_bundle_path()
	
#chdir here so that relative RPATHs line up ('./lib')
os.chdir(activity_root) 
	
#append to sys.path for the python packages
sys.path.append(os.path.join(activity_root, 'site-packages'))

#possibly load daemon
try:
	os.stat(os.path.join(os.path.expanduser('~/.mpd/pid_file')))
except:
	cmd = activity_root + "/bin/mpd_control.sh start"
	p = subprocess.Popen(cmd, shell=True, close_fds=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
	retval = p.wait()
	stderr = p.stderr.read()
	print stderr
	if len(stderr) > 1 or retval != 0:
		logging.error('unable to start mpd')
	p_output = p.stdout.read()
	print p_output


logging.info('activity ready to load')

class SonataActivity(activity.Activity):
	def __init__(self, handle):
		activity.Activity.__init__(self, handle)
		
		toolbox = activity.ActivityToolbox(self)
		self.set_toolbox(toolbox)
		toolbox.show()
		
		app = sonata.Base(self, True)
		logging.info('done setting up sonata')
		self.set_title('Sonata')
		
		
if __name__ == '__main__': # Here starts the dynamic part of the program
	import pygtk
	pygtk.require("2.0")
	import gtk
	window = gtk.Window()
	app = sonata.Base(window, True)
	logging.info('done setting up sonata')
	gtk.main()
