coffee -c -o lib/ src/
coffee -c -o lib/ test/
echo "#!/usr/bin/env node" > lib/test_router.tmp
echo " " >> lib/test_router.tmp
cat lib/test_router.js >> lib/test_router.tmp
mv lib/test_router.tmp lib/test_router.js
chmod +x lib/test_router.js