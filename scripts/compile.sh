#!/bin/sh

echo "Compiling src"
coffee -c -o lib/ src/

scripts/compile_test.sh

echo "Generating mk-server"
echo "#!/usr/bin/env node" > bin/mk-server
echo " " >> bin/mk-server
cat lib/mk-server.js >> bin/mk-server
chmod +x bin/mk-server
rm lib/mk-server.js

