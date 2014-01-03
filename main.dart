library gameserver;

import "dart:async";
import "dart:core";
import 'dart:convert';
import "dart:io";
import "dart:isolate";

part 'rest.dart';
part 'game.dart';

// Stores all game objects
var _GameMapData;

// Receive port for the Isolate
var receivePort = new RawReceivePort();

get GameMap {
  if (_GameMapData == null) {
    // TODO initialization from DataBase.
    _GameMapData = new Map<int, Game>();
  }
  return _GameMapData;
}

void main() {
  var counter = 0; // setup a counter
  // TODO Put this in a config file

  var restPort = 8000;
  final restHost = InternetAddress.ANY_IP_V4;

  print('Main Server: Port:$restPort');

  // Start up REST endpoint
  HttpServer.bind(restHost, restPort).then((server) {
    server.listen(restListener);
  });

  // Receive messages from the Isolates
  receivePort.handler = (message) {
    print('Main: New Isolate: ${message[0]}, ${message[1]}');

    // Record which port the isolate chose
    var id = int.parse(message[0]);

    // Lookup the object and set the port
    if (GameMap.isNotEmpty && GameMap.containsKey(id)) {
      var GameObj = GameMap[id];
      // Set the websocket port
      GameObj.port = message[1];
      // Set the listening port
      GameObj.sendPort = message[2];
    }
  };

  // Setup an example timer
  new Timer.periodic(new Duration(seconds:10), (timer) {
    counter++;
    if (counter <= 1000) {
      print('Main: Sending ping: $counter');
      var mapData = new Map();
      mapData["type"] = "ping";
      mapData["date"] = (new DateTime.now().millisecondsSinceEpoch) ~/ 1000;

      String jsonData = JSON.encode(mapData);

      // Iterate through all Games
      var keys = GameMap.keys;
      GameMap.forEach((key,value) => value.sendPort.send(jsonData));
    }
    else {
      timer.cancel(); // stop the timer running
    }
  });
}
