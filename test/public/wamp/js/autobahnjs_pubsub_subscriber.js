// Make code portable to Node.js without any changes
try {
   var autobahn = require('autobahn');
} catch (e) {
   // when running in browser, AutobahnJS will
   // be included without a module system
}

// Set up WAMP connection to router
var connection = new autobahn.Connection({
   url: 'ws://'+ location.host + '/wamp',
   realm: 'tutorialpubsub'}
);

var global = global ? global : window ? window : {};

// Set up 'onopen' handler
connection.onopen = function (session) {
   global.session = session;
   global.currentSubscription = null;

   // Define an event handler
   global.onEvent = function onEvent(args, kwargs, details) {

      console.log("Event received ", args, kwargs, details);

      if ( args[0] > 20 ) {
         console.log("Will try to unsubscribe now, cause this is very boring... ;-(");
         session.unsubscribe(currentSubscription).then(

            function(gone) {
               console.log("unsubscribe successfull");
            },

            function(error) {
               console.log("unsubscribe failed", error);
            }

         );
      }

   }

   // Subscribe to a topic
   global.do_subscribe = function do_subscribe() {
    session.subscribe('com.myapp.topic1', onEvent).then(

        function(subscription) {
            console.log("subscription successfull", subscription);
            console.log ("subscription id: ", subscription.id ? subscription.id : 'subscription has no id');
            currentSubscription = subscription;
        },

        function(error) {
            console.log("subscription failed", error);
        }

    );
   };

   do_subscribe();

};

// Open connection
connection.open();
