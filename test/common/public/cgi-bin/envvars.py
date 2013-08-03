#!/usr/bin/env python

import os, sys, json

print 'Content-type: text/html'
print '\n'

print '<h2 style="text-align: center;">Environment variables and other nice stuff...</h2><hr/>'
#for key in os.environ:
  #print "<p>%s = %s</p>" % (key, os.environ[key])
print "<p>%s = %s</p>" % ('REMOTE_ADDRESS', os.environ.get('REMOTE_ADDRESS'))
print "<p>%s = %s</p>" % ('REQUEST_URL', os.environ.get('REQUEST_URL'))
print "<p>%s = %s</p>" % ('QUERY_STRING', os.environ.get('QUERY_STRING'))

print "<hr/>"

obj = json.loads(sys.stdin.readline())

for key in obj:
  print "%s = %s<br/>" % (key, obj[key])

sys.stdout.flush()        
sys.exit(0)




