// Make code portable to Node.js without any changes
try {
   var autobahn = require('autobahn');
} catch (e) {
   // when running in browser, AutobahnJS will
   // be included without a module system
}


// Set up WAMP connection to router
var protocol = location.protocol == 'https:' ? 'wss:' : 'ws:'
var connection = new autobahn.Connection({
        url: protocol + '//'+ location.host + '/wamp',
        realm: 'tutorialrpc'}
);

// Set up 'onopen' handler
connection.onopen = function (session) {
    console.log("Session opened - Id: ", session.id)
    // Define the remote procedure
   function utcnow() {
      now = new Date();
      console.log(now.toISOString());
      return now.toISOString();
   }

   // Register the remote procedure with the router
   session.register('com.timeservice.now', utcnow).then(
      function (registration) {
         console.log("Procedure registered:", registration.id);
      },
      function (error) {
         console.log("Registration failed:", error);
      }
   );
};

// Open connection
connection.open();
