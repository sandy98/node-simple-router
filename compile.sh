coffee -c -o lib/ src/
coffee -c test/

echo "Generating test_router.js"
echo "#!/usr/bin/env node" > test/common/test_router.tmp
echo " " >> test/common/test_router.tmp
cat test/common/test_router.js >> test/common/test_router.tmp
mv test/common/test_router.tmp test/common/test_router.js
chmod +x test/common/test_router.js

echo "Generating uploader/server.js"
echo "#!/usr/bin/env node" > test/uploader/server.tmp
echo " " >> test/uploader/server.tmp
cat test/uploader/server.js >> test/uploader/server.tmp
mv test/uploader/server.tmp test/uploader/server.js
chmod +x test/uploader/server.js

echo "Generating mk-server"
echo "#!/usr/bin/env node" > bin/mk-server
echo " " >> bin/mk-server
cat lib/mk-server.js >> bin/mk-server
chmod +x bin/mk-server

rm lib/mk-server.js

