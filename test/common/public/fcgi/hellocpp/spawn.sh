#spawn-fcgi -p 9510 -- ./hellocpp
umask 0111 && spawn-fcgi -s /tmp/hellocpp.sk -- ./hellocpp
