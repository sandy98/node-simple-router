#!/usr/bin/env python

import random, sys
from wsgiref.simple_server import make_server

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

httpd = make_server('', 9500, simple_app)
print "Serving on port 9500..."
httpd.serve_forever()




