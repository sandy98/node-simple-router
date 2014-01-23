#!/usr/bin/env ruby

require 'cgi'

cgi = CGI.new

#puts "Content-Type: text/html\n"
puts cgi.header
puts "<h2 style='text-align: center;'>Hello from Ruby to Node.js!</h2>"

#data = gets()
#if data
#  puts data
#end


fields = cgi.keys

if fields
  puts "<ul>"
  for field in fields
    puts "<li>#{field} = <strong>#{cgi[field]}</strong></li>"
  end
  puts "</ul>"
else
 puts "No CGI input"
end

puts "<a href='javascript: history.back();'>Back to Form</a>"

