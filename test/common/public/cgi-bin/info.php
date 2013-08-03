#!/usr/bin/env php-cgi

<?php
 //$line = trim(fgets(STDIN));
 $stdin = fopen('php://stdin', 'r');
 $line = trim(fgets($stdin));
 echo "<h1 style='text-align: center; color: #f24; font-size: 24pt; text-shadow: 3px 3px gray;'>PHP Info for Node.js</h1>";
 echo "<hr/><div style='text-align: center;'>Raw data from the server: <strong>".$line."</strong></div><hr/><p>&nbsp;</p><p>&nbsp;</p>";
 phpinfo();

?>
