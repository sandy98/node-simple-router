#!/bin/sh

echo "Content-Type: text/html"
echo ''
echo ''
echo "<h2 style='text-align: center;'>Hello from bash!!!</h2>"

read vars
echo "<p>"
echo $vars
echo "</p>"

echo "<p>"
echo "QUERY STRING: $QUERY_STRING"
echo "</p>"
