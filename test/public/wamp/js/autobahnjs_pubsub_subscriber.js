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

global.maxEvents = 20;

var log = function(msg) {
    document.getElementById('log').innerHTML = msg;
};

// Set up 'onopen' handler
connection.onopen = function (session) {
   global.session = session;
   global.currentSubscription = null;

   // Define an event handler
   global.onEvent = function onEvent(args, kwargs, details) {

      log("Event received " + JSON.stringify(args) + JSON.stringify(kwargs) + JSON.stringify(details));

      if ( args[0] > global.maxEvents ) {
         log("Will try to unsubscribe now, cause this is very boring... ;-(");
         session.unsubscribe(currentSubscription).then(

            function(gone) {
               log("Unsubscribe successfull");
            },

            function(error) {
               log("Unsubscribe failed: " + error);
            }

         );
      }

   }

   // Subscribe to a topic
   global.do_subscribe = function do_subscribe() {
    session.subscribe('com.myapp.topic1', onEvent).then(

        function(subscription) {
            log("Subscription successfull: " + subscription.id);
            log ("Subscription id: " + subscription.id ? subscription.id : 'subscription has no id');
            currentSubscription = subscription;
        },

        function(error) {
            log("Subscription failed: " + error);
        }

    );
   };

   do_subscribe();

};

// Open connection
connection.open();
