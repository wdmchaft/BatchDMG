#!/usr/bin/env python
"""
 batchdmg.py
 Batch-create DMG files from mounted media
 @author Filipp Lepalaan <filipp@mac.com>
 @created 20.10.2009
 @updated 21.10.2009
 http://developer.apple.com/cocoa/pyobjc.html
 NSRunLoop must be used instead of threads or forking
"""
import sys, time
from AppKit import *
from subprocess import Popen
    
class Imager(NSObject):
  def init(self):
    nc = NSWorkspace.sharedWorkspace().notificationCenter()
    nc.addObserver_selector_name_object_(self, "observeCenter:", "NSWorkspaceDidMountNotification", None)
    print "Waiting for media..."
    
  def observeCenter_(self, notification):
    ui = notification.userInfo()
    path = ui['NSDevicePath'].encode("utf-8")
    name = ui['NSWorkspaceVolumeLocalizedNameKey'].encode("utf-8")
    util = "/usr/bin/hdiutil"
    print "  - imaging '%s'" % (name)
    cmd = [util, "create", "-format", "UDBZ", "-srcfolder", path, name+".dmg"]
    
    Popen(cmd, shell=False).communicate()
    Popen([util, "eject", "-quiet", path], shell=False).communicate()
    
    print "Ejecting '%s'" % (name)
    print "Waiting for media..."
  
  def dealloc(self):
    nc = NSWorkspace.sharedWorkspace().notificationCenter()
    nc.removeObserver_(self)

rl = NSRunLoop.currentRunLoop()
s = Imager.alloc().init()
rl.run()