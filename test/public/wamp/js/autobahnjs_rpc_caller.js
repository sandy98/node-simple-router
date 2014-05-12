// Make code portable to Node.js without any changes
try {
   var autobahn = require('autobahn');
} catch (e) {
   // when running in browser, AutobahnJS will
   // be included without a module system
}

var log = function(msg) {
    document.getElementById('log').innerHTML = msg;
};


// Set up WAMP connection to router
var protocol = location.protocol == 'https:' ? 'wss:' : 'ws:'
var connection = new autobahn.Connection({
   url: protocol + '//'+ location.host + '/wamp',
   realm: 'tutorialrpc'}
);

// Set up 'onopen' handler
connection.onopen = function (session) {
   log("Session opened - Id: " + session.id);
   setInterval(function() {
      session.call('com.timeservice.now').then(
         // RPC success callback
         function (now) {
            log("Current time: " + now.args[0]);
         },
         // RPC error callback
         function (error) {
            log("Call failed: " + error);
         }
      );
   }, 1000);
};

// Open connection
connection.open();
