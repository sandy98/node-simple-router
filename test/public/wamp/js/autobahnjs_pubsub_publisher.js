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
        url: protocol + '//'+ location.host + '/wampchat',
        realm: 'tutorialrpc'}
);

var global = global ? global : window ? window : {};

var log = function(msg) {
    document.getElementById('log').innerHTML = msg;
};

// Set up 'onopen' handler
connection.onopen = function (session) {

   // Start publishing events
   var counter = 0;

   global.timed_pub = function timed_pub() {

      if (session.isOpen) {
        session.publish ('com.myapp.topic1', [ counter ], {}, { acknowledge: true}).then(

           function(publication) {
              log("Published to topic 'com.myapp.topic1'<br/> Publication ID is " + publication.id);
           },

           function(error) {
               log("Publication error: " + error);
           }

        );
      }

      counter += 1;

   };

   global.setTimer = function setTimer() {
     global.timer = setInterval (timed_pub , 1000 );
   };

   global.clearTimer = function clearTimer() {
     clearInterval(global.timer);
   };

   global.setTimer();
};

// Open connection
connection.open();
