
<?php
 //$line = trim(fgets(STDIN));
 //$stdin = fopen('php://stdin', 'r');
 //$line = trim(fgets($stdin));
 //$line = $_GET;
 
 
 echo "<style>h3 {text-align: center;}</style>";
 echo "<title>Another simple PHP proof of concept</title>";
 echo "<h1 style='text-align: center; color: #f24; font-size: 24pt; text-shadow: 3px 3px gray;'>PHP variables taken from Node.js server</h1>";
 echo "<hr/><div style='text-align: center;'>Request method: <strong>".$_SERVER['REQUEST_METHOD']."</strong></div><hr/>";
 
 echo "<h3>GET variables</h3>"; 
 foreach($_GET as $key=>$val)   
   echo "<hr/><div style='text-align: center;'>".$key.": <strong>".$val."</strong></div>";
 
 echo "<h3>POST variables</h3>"; 
 foreach($_POST as $key=>$val)   
   echo "<hr/><div style='text-align: center;'>".$key.": <strong>".$val."</strong></div>";
 
 echo "<h3>ALL variables</h3>"; 
 foreach($_REQUEST as $key=>$val)   
   echo "<hr/><div style='text-align: center;'>".$key.": <strong>".$val."</strong></div>";

echo "Raw post data: ".$HTTP_RAW_POST_DATA."<hr/>";
echo "Stdin contents: ".file_get_contents('php://stdin')."<hr/>";
echo "Input contents: ".file_get_contents('php://input')."<hr/>";

echo "<p>&nbsp;</p><p><a href='/cgitest.html'>Back to Form</a></p>";

?>
