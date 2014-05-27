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


var connection2 = new autobahn.Connection({
        url: protocol + '//'+ location.host + '/wamp',
        realm: 'test'}
);

var session2;

// Set up 'onopen' handler
connection2.onopen = function (session) {
    log("Session 2 opened - Id: " + session.id);
    session2 = session;
};
// Open connection
connection2.open();

var sum1 = document.getElementById("sum1");
var sum2 = document.getElementById("sum2");
var resultSpan = document.getElementById("result");

var onInput = function onInput(evt) {
    console.log("Calling RPC localhost.test.add2 with arguments: " + sum1.value + ", " + sum2.value);
    session2.call('localhost.test.add2', [parseInt(sum1.value), parseInt(sum2.value)])
    .then(function(result) {
            console.log("RPC result received: ", JSON.stringify(result));
            resultSpan.innerHTML = result.args[0];
        });
}

sum1.addEventListener("input", onInput);
sum2.addEventListener("input", onInput);