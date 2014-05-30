       var form_uploader, 
       file_uploader, 
       msg_list, 
       change_mycolor, 
       user_name, 
       txt_msg, 
       ws, 
       chatters = [], 
       chatters_list,
       protocol = location.protocol == 'https:' ? 'wss:' : 'ws:',  
       url = protocol + '//' + location.host + '/';

       var addMsg = function(msg) {
          var new_msg = document.createElement('div');
          new_msg.innerHTML = '<span style="color: ' + msg.color + ';">' + msg.from + ':&nbsp;&nbsp;&nbsp;</span><span>' + msg.body + '</span>';
          msg_list.appendChild(new_msg);
          msg_list.scrollTop = msg_list.scrollHeight;
          return msg;
       };

       var setKey = function(sock, key, value) {
         sock[key] = value;
         if (key == 'color') {
           user_name.style.backgroundColor = value;
         }
       };
	
       var showChatters = function() {
         var li, color, name, rt, background;
         chatters_list.innerHTML = '';
         //console.log("In showChatters chatters list is: ", chatters);
         for (index in chatters) {
           li = document.createElement('li');
           li.className = 'list-group-item';
           color = chatters[index].color
           name = chatters[index].username
           rt = chatters[index].currentRoundTrip
           background = "#00cc00";
           if (rt > 0.3 && rt < 0.75) {background = "#ffbf00";}
           if (rt >= 0.75) {background = "#cc0000";}
           li.innerHTML = '<span style="color: ' + color + ';">' + name + '</span><span style="background: ' + background + '" class="badge">' + rt  + '</span>';
           li.attributes['data-id'] = chatters[index].id;
           chatters_list.appendChild(li);
         }
       };

       var processMessage = function(sock, msg) {
         var headers = msg.headers;
         var body = msg.body;
         var msgCommand = headers.command;
         switch (msgCommand) {
	   case 'chat-message':
             addMsg({from: headers.from, body: body, color: headers.color});
             break;
           case 'set':
             key = headers.key;
             value = body;
             setKey(sock, key, value);
             break;
           case 'chatters-list':
             if (headers.subcommand == 'init') {
               chatters = body;
               //console.log("Received these chatters:", chatters); 
             }
             showChatters();
             break;
           default:
             alert("Received an unrecognized message: " + body);
	 }
       };	

       var set_username = function(username) {
         try {
           ws.username = username;
           ws.send(JSON.stringify({headers: {command: 'set', key: 'username'}, body: username}));
         }
         catch(e) {console.log("Error:", e.message);}
         user_name.innerHTML = username;
         if (username.length == 0) {
           user_name.style.display = 'none';
           change_mycolor.style.display = 'none';
	 }
         else {
           user_name.style.display = 'inline';
           change_mycolor.style.display = 'inline';
         }
       };	

       
       var ws_init = function() {
         ws = new WebSocket(url);
         ws.onopen = function() {
	       console.log("Client socket open.");
           var username;
           while (!username || username.length == 0) {
             username = prompt("Please input your username to be used in the chat.");
             if (username && username.length != 0) {
               set_username(username);
               txt_msg.focus();
             }
	       }
         };           
         ws.onclose = function() {
           txt_msg.value = '';
           msg_list.innerHTML = '';
           chatters = [];
           chatters_list.innerHTML = '';
           set_username('');
	       if (confirm("Client socket closed, so chat will no longer work. Care to try reconecting?")) {
	         ws_init();
	       }
         };           
         ws.onerror = function(e) {
           txt_msg.value = "";
	   alert("Client socket issued an error:", e.message);	
         };           
         ws.onmessage = function(msg) {
	   //console.log("Client socket sent: " + JSON.stringify(msg.data));
           processMessage(ws, JSON.parse(msg.data));	
         };
         return ws;
       };
 
       var onLoad = function onLoad() {
         //alert("Window loaded");
         msg_list = document.getElementById('msg-list');
	     change_mycolor = document.getElementById('change-mycolor');
	     txt_msg = document.getElementById('txt-msg');
	     user_name = document.getElementById('user-name');
         chatters_list = document.getElementById('chatters-list');
	     form_uploader = document.getElementById('form-uploader');
         file_uploader = document.getElementById('file-uploader');

	     var ws = ws_init();

         window.onunload = function() {
             console.log("Closing websocket...");
             ws.close();
         };

         var showFileInChat = function showFileInChat(file) {
           try {
             console.log(file);
 	     if (file.type.indexOf('image') == -1) {
               return alert("'" + file.name + "' is not a picture. Please choose a picture file to send."); 
             }
             if (file.size > 1048576) {
               return alert("'" + file.name + "' is too big. Please choose a picture file smaller than 1 megabyte."); 
             }
             var reader = new FileReader();
	         reader.onload = function(evt) {
               var base64image = evt.target.result;
               var body = '' + txt_msg.value + ' <img src="' + base64image + '" />'
               var payload = JSON.stringify({headers: {command: 'chat-message', from: ws.username || ws.id, color: ws.color || "#880000"}, body: body});
               ws.send(payload);
               txt_msg.value = "";
             };
             //reader.readAsBinaryString(file);
             reader.readAsDataURL(file);
           }
           catch(e) {
             console.log("ERROR happened: " + e.message);
           }  	
         };

         var dragOver = function dragOver(evt) {
             if (evt.preventDefault) {evt.preventDefault();}
          
             var canvas = document.createElementNS("http://www.w3.org/1999/xhtml","canvas");
             canvas.width = canvas.height = 50;

             var ctx = canvas.getContext("2d");
             ctx.lineWidth = 4;
             ctx.moveTo(0, 0);
             ctx.lineTo(50, 50);
             ctx.moveTo(0, 50);
             ctx.lineTo(50, 0);
             ctx.stroke();

             var dt = evt.dataTransfer;
             dt.setData('text/plain', 'Data to Drag');
             dt.setDragImage(canvas, 25, 25);
             return false;
	 };
        
	var drop = function drop(evt) {
          if (evt.preventDefault) {evt.preventDefault();}
          var dt = evt.dataTransfer;
	  //alert('Items: ' + dt.items.length + " - Files: " + dt.files.length);
          if (dt.files.length > 0) {
            for (index in dt.files) {
              console.log(dt.files[index]);
              showFileInChat(dt.files[index]);
            } 
	  }
          return false;     	
	};
 
         txt_msg.addEventListener('keypress', function(evt) {
           if (ws.readyState != 1) {
             if (evt.preventDefault) evt.preventDefault();
             txt_msg.value = "";
             return false;
           }
           if (evt.which != 13)
             return false;
           var value = txt_msg.value;
           if (value.length > 0) {
             var payload = JSON.stringify({headers: {command: 'chat-message', from: ws.username || ws.id, color: ws.color || "#880000"}, body: value});
             ws.send(payload);
             txt_msg.value = "";
           }
           return false;
         });           

	 change_mycolor.addEventListener('click', function(evt) {
           ws.send(JSON.stringify({headers: {command: 'reset-color'}}));
         });
    
         form_uploader.addEventListener('submit', function(evt) {
           if (evt.preventDefault) {evt.preventDefault();}
           if (!file_uploader.files.length) {
             return alert("Please choose a picture file to send."); 
           }
	   var file = file_uploader.files[0];
           showFileInChat(file);

	 });

         msg_list.addEventListener('dragenter', dragOver);
         msg_list.addEventListener('dragover', dragOver);
         msg_list.addEventListener('drop', drop);
         document.body.addEventListener('paste', function(evt) {
           evt.dataTransfer = evt.clipboardData;
           //console.log(evt.clipboardData);
           //console.log(evt.dataTransfer);
           drop(evt);
         });

       };
       
       window.onload = onLoad;	

