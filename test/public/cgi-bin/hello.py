#!/usr/bin/env python

import random, sys

print 'Content-type: text/html'
print '\n'

for i in range(1, random.randint(2, 11)):
    output = '<h3>Hello, World No <span style="color: red;">%0.2d</span></h3>' % i
    sys.stderr.write("%s\n" % output)
    sys.stdout.write("%s\n" % output)
    
    



