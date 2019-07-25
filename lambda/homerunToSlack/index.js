'use strict';

var https = require('https');
var redis = require('redis');

exports.handler = (event, context, callback) => {
    var bomb = parseTweet(event.tweet) 
    
    getPlayerUser(bomb.fullName, function(user) {
      var message = bomb.fullName + " has BOMBED!!! (" + bomb.count + ")";
      if(user) {
        message += " - <@" + user + ">";
      }
      
      var data = JSON.stringify({
        text: message,
        icon_emoji:":bomb:",
        username:"Bombs",
        channel: "#bombs"
      });
      
      var options = {
        host: 'hooks.slack.com',
        port: 443,
        path: '/services/' + process.env.slackToken,
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': data.length
        }
      };
  
      var req = https.request(options, function(res) {
        console.log("Request made");
        var data = "";
        res.on('data', function(chunk) {
          data += chunk;
        });
        
        res.on('end',function() {
            console.log("Received response " + data);
            
            var response = {
              "statusCode": 200,
              "headers": {
                  "Content-type": "application/json"
              },
              "body": JSON.stringify({message: 'Hello from Lambda!'}),
              "isBase64Encoded": false
            };
            
            callback(null, response); 
        });
      });
      
      req.write(data);
      req.end();
      
    })
        
};

function parseTweet(tweet) {
  var match = tweet.match(/(([A-Za-z\-.]+)\s(.*))\s-\s(.+)\s[(](\d+)[)]/);
  
  return {
    fullName: match[1],
    firstName: match[2],
    lastName: match[3],
    team: match[4],
    count: match[5]
  }
}

function getPlayerUser(name, callback) {
  var client = redis.createClient({
    host: process.env.redisHost,
    port: process.env.redisPort,
    password: process.env.redisPassword
  });
  
  client.get("player:" + name, function(err, value) {
    callback(value);
    client.end(true)
  });
}