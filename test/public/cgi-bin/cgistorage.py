#!/usr/bin/env python

import cgi


form = cgi.FieldStorage()

print "Content-Type: text/html"
print

print "<title>Python using cgi module</title>"

print "<h1 style='text-align: center; color: #880000;'>Python CGI script</h1>"

if len(form) == 0:
  print "<p>No data received</p>"
else:
  print "<ul>"
  for key in form.keys():
    print "<li>%s = <strong>%s</strong></li>" % (key, form[key].value)
  print "</ul>"
  
print "<p>&nbsp;</p><p><a href='javascript: history.back();'>Back to Form</a></p>"