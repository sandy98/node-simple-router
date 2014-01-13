#!/usr/bin/env python2

import random, sys, os
from flup.server.fcgi import WSGIServer

current = 0

def simple_app(environ, start_response):
    global current
    status = '200 OK'
    headers = [('Content-type', 'text/html')]
    start_response(status, headers)
    ret = []
    ret.append('<title>Hello from Python</title>')
    for i in range(1, random.randint(2, 11)):
	ret.append('<h3>Hello, World No <span style="color: red;">%0.2d</span></h3>' % i)
    
    f = open('current.txt', 'r')
    current = int(f.read())
    f.close()
    current += 1
    f = open('current.txt', 'w')
    f.write(str(current))
    f.close()
    ret.append('<p>&nbsp;</p><p>Current request: <strong>%s</strong></p>' % (current,))    
    return ret

print "Serving fcgi content..."
os.umask(0o111)
#WSGIServer(simple_app, bindAddress=('', 9500)).run()
WSGIServer(simple_app, bindAddress='/tmp/hello_fcgi_py.sk').run()




