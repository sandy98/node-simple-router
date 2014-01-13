
import random, sys, os, cgi
#from flup.server.fcgi import WSGIServer

current = 0

def application(environ, start_response):
    global current
    status = '200 OK'
    headers = [('Content-type', 'text/html')]
    start_response(status, headers)
    ret = []
    ret.append('<title>Hello from Python</title>')
    for i in range(1, random.randint(2, 11)):
	ret.append('<h3>Hello, World No <span style="color: blue;">%0.2d</span></h3>' % i)
    
    f = open('current.txt', 'r')
    current = int(f.read())
    f.close()
    current += 1
    f = open('current.txt', 'w')
    f.write(str(current))
    f.close()
    ret.append('<p>&nbsp;</p><p>Current request: <strong>%s</strong></p>' % (current,))    
    form = cgi.FieldStorage(fp = environ['wsgi.input'], environ = environ, keep_blank_values = 1)
 
    ret.append('<ul>')
    
    try:
        if len(form.keys()) == 0:
            ret.append('<li style="color: red;">Got no data</li>')
        else:
            for key in form.keys():
                ret.append('<li>%s: <strong>%s</strong></li>' % (key, form[key].value))
    except:
        ret.append('<li style="color: red;">Got no data due to error.</li>')
      
    ret.append('</ul><hr/>')

    cgi.print_environ()
    
    return ret

#print "Serving fcgi content..."
#os.umask(0o111)
#WSGIServer(simple_app, bindAddress=('', 9500)).run()
#WSGIServer(simple_app, bindAddress='/tmp/hello_fcgi_py.sk').run()





