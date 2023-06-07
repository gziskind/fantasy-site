'use strict';

var https = require('https');
var redis = require('redis');
var querystring = require('querystring')
var async = require('async')

exports.handler = (event, context, callback) => {
  var client = redis.createClient({
    host: process.env.redisHost,
    port: process.env.redisPort,
    password: process.env.redisPassword
  });
  
  client.get("twitter:last_id" , function(err, value) {
    queryTwitter(value, callback)
    client.end(true)
  });
}

function queryTwitter(last_id, callback) {
  var queryObj = {
    'query': 'from:mlbhr OR from:mlbsteals',
    'tweet.fields': 'author_id',
    "max_results": 100
  }

  if(last_id) {
    queryObj['since_id'] = last_id
  }

  var query = querystring.encode(queryObj)

  var options = {
      host: 'api.twitter.com',
      port: 443,
      path: `/2/tweets/search/recent?${query}`,
      method: 'GET',
      headers: {
          "User-Agent": "v2RecentSearchJS",
          "authorization": `Bearer ${process.env.twitterToken}`
      }
  }

  var req = https.request(options, function(res) {
      var data = '';

      res.on('data', function(chunk) {
          data += chunk;
      })

      res.on('end', function() {
        parseTwitter(JSON.parse(data), callback)
      })
  })

  req.end();
}

function parseTwitter(data, callback) {
  if(data.meta.result_count > 0) {
    var client = redis.createClient({
      host: process.env.redisHost,
      port: process.env.redisPort,
      password: process.env.redisPassword
    });
    
    client.set("twitter:last_id" , data.meta.newest_id, function(err, res) {
      var asyncTasks = []
      data.data.reverse().forEach(function(stat) {
        asyncTasks.push(function(callback) {
          var event = { tweet: stat.text }
          if(stat.author_id == 612985010) {
            event.stat = 'homerun'
          } else {
            event.stat = 'steal'
          }
          
          console.log("Got tweet: " + stat.text)

          sendAlert(event, {}, callback)
        })
      })

      async.series(asyncTasks, function() {
        var response = {
          "statusCode": 200,
          "headers": {
              "Content-type": "application/json"
          },
          "body": JSON.stringify({message: 'Hello from Lambda!'}),
          "isBase64Encoded": false
        };
        
        callback(null, response); 
      })

      client.end(true)
    });
  } else {
    var response = {
      "statusCode": 200,
      "headers": {
          "Content-type": "application/json"
      },
      "body": JSON.stringify({message: 'No new updates'}),
      "isBase64Encoded": false
    };
            
    callback(null, response); 
  }
}

function sendAlert(event, context, callback) {
    var info = null;
    if(event.stat == "homerun") {
      info = parseBombTweet(event.tweet);
    } else if(event.stat == "steal") {
      info = parseStealTweet(event.tweet);
    }
    
    getPlayerUsers(info.fullName, event.stat, function(users) {
      var slack_users = getSlackUsers(users)
      var telegram_users = getTelegramUsers(users)
      
      var asyncTasks = []
      
      if(slack_users.length > 0) {
        asyncTasks.push(function(asyncCallback) {
          sendToSlack(info, slack_users, event.stat, asyncCallback)
        })
      }
      
      if(telegram_users.length > 0) {
        asyncTasks.push(function(asyncCallback) {
          sendToTelegram(info, telegram_users, event.stat, asyncCallback)
        })
      }
      
      async.parallel(asyncTasks, function() {
        callback()
      })
    })
        
};

function getSlackUsers(users) {
  var slackUsers = []
  
  users.forEach(function(user) {
    if(user.startsWith("U")) {
      slackUsers.push(user)
    }
  })
  
  return slackUsers
}

function getTelegramUsers(users) {
  var telegramUsers = []
  
  users.forEach(function(user) {
    if(!user.startsWith("U")) {
      telegramUsers.push(user)
    }
  })
  
  return telegramUsers;
}

function sendToTelegram(info, users, stat, callback) {
  var asyncTasks = []
  
  users.forEach(function(user) {
    asyncTasks.push(function(asyncCallback) {
      var message = null;
      if(stat == "homerun") {
        message = info.fullName + " has BOMBED!!! (" + info.count + ")";
      } else if(stat == "steal") {
        message = info.fullName + " has stolen a base!";
      }
      
      var data = JSON.stringify({
        text: message,
        chat_id: user
      });
      
      var options = {
        host: "api.telegram.org",
        port: 443,
        path: '/bot' + process.env.telegramToken + "/sendMessage",
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': data.length
        }
      }
      
      var req = https.request(options, function(res) {
        var response = "";
        res.on('data', function(chunk) {
          response += chunk;
        });
        
        res.on('end',function() {
            asyncCallback(); 
        });
      });

      req.write(data);
      req.end();
    })
  })
  
  async.parallel(asyncTasks, function() {
    callback()
  })
}

function sendToSlack(info, users, stat, callback) {
  var data = null;
  if(stat == "homerun") {
    data = getBombMessageForSlack(info, users)
  } else if(stat == "steal") {
    data = getStealMessageForSlack(info, users)
  }
  
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
    var response = "";
    res.on('data', function(chunk) {
      response += chunk;
    });
    
    res.on('end',function() {
        callback(); 
    });
  });
  
  req.write(data);
  req.end();
}

function getBombMessageForSlack(info, users) {
  var message = info.fullName + " has BOMBED!!! (" + info.count + ")";
  if(users.length > 0) {
    message += " -"
    users.forEach(function(user) {
      message += " <@" + user + ">";
    })
  }
  
  var data = JSON.stringify({
    text: message,
    icon_emoji:":bomb:",
    username:"Bombs",
    channel: "#bombs"
  });
  
  console.log(message)
  
  return data;
}

function getStealMessageForSlack(info, users) {
  var message = info.fullName + " has stolen a base!";
  if(users.length > 0) {
    message += " -"
    users.forEach(function(user) {
      message += " <@" + user + ">";
    })
  }
  
  var data = JSON.stringify({
    text: message,
    icon_emoji:":steal:",
    username:"Steals",
    channel: "#steals"
  });
  
  console.log(message)
  
  return data
}

function parseBombTweet(tweet) {
  var match = tweet.match(/(([A-Za-z\-.]+)\s(.*))\s-\s(.+)\s[(](\d+)[)]/);
  
  return {
    fullName: match[1],
    firstName: match[2],
    lastName: match[3],
    team: match[4],
    count: match[5]
  }
}

function parseStealTweet(tweet) {
  var match = tweet.match(/(([A-Za-z\-.]+)\s(.*))\s-\s(.+)/);
  
  return {
    fullName: match[1],
    firstName: match[2],
    lastName: match[3]
  }
}

function getPlayerUsers(name, stat, callback) {
  var client = redis.createClient({
    host: process.env.redisHost,
    port: process.env.redisPort,
    password: process.env.redisPassword
  });
  
  client.get("player-" + stat  + ":" + name, function(err, value) {
    if(value == null) {
      callback([]);
    } else {
      callback(value.split(','));
    }
    client.end(true)
  });
}