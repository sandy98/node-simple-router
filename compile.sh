coffee -c -o lib/ src/
coffee -c test/

echo "Generating test/server.js"
echo "#!/usr/bin/env node" > test/server.tmp
echo " " >> test/server.tmp
cat test/server.js >> test/server.tmp
mv test/server.tmp test/server.js
chmod +x test/server.js

echo "Generating mk-server"
echo "#!/usr/bin/env node" > bin/mk-server
echo " " >> bin/mk-server
cat lib/mk-server.js >> bin/mk-server
chmod +x bin/mk-server

rm lib/mk-server.js

