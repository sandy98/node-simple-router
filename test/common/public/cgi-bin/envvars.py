#!/usr/bin/env python

import os, sys

from urllib import unquote

def qs2obj(q):
   ret = {}
   items = q.split('&')
   for item in items:
       newitem = item.split('=')
       ret[unquote(newitem[0])] = unquote(newitem[1])
   return ret

print 'Content-type: text/html'
print '\n'

print '<h2 style="text-align: center;">Environment variables and other nice stuff...</h2><hr/>'

#print "<p>%s = %s</p>" % ('REMOTE_ADDRESS', os.environ.get('REMOTE_ADDRESS'))
#print "<p>%s = %s</p>" % ('REQUEST_URI', os.environ.get('REQUEST_URI'))
#print "<p>%s = %s</p>" % ('QUERY_STRING', os.environ.get('QUERY_STRING'))

for key in os.environ:
  print "<p>%s = %s</p>" % (key, os.environ[key])

print "<hr/>"

querystring = sys.stdin.readline()
print "Raw data from web server: %s<br/>" % (querystring,)

print "<hr/>"


obj = qs2obj(querystring)

for key in obj:
  print "%s: <strong>%s</strong><br/>" % (key, obj[key])

print "<hr/>"

sys.stdout.flush()        
sys.exit(0)




