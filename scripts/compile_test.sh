echo "Compiling test"
coffee -c test/server.coffee

echo "Generating test/server.js"
echo "#!/usr/bin/env node" > test/server.tmp
echo " " >> test/server.tmp
cat test/server.js >> test/server.tmp
mv test/server.tmp test/server.js
chmod +x test/server.js


