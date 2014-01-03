
// Gameserver Library
// This handles all REST connections
part of gameserver;

// URL Prefix for versioning
final rest_prefix = "/v1";

// Set content type
final rest_content_type = "application/json";

String getEncodedGame(id) {

  var GameObj = GameMap[id];
  var jsonoutput = '{"id": ${GameObj.id}, "object": "game", "title": "${GameObj.title}", "status": "${GameObj.status}", "port": "${GameObj.port}"}';
  return jsonoutput;

}

// REST Listener
void restListener(request) {

  print('REST: ${request.method}: ${request.uri.path}');

  // Set to JSON
  request.response.headers.add(HttpHeaders.CONTENT_TYPE, "${rest_content_type}");

  // URL: /v1/games/:id
  RegExp gamesExp = new RegExp(r"(/v1/games/\d?)");
  String str = request.uri.path;
  Iterable<Match> matches = gamesExp.allMatches(str);

  if (matches.length == 1) {
    switch (request.method) {

      case 'POST':
        // Create a new game
        List<int> postBody = new List<int>();
        request.listen(postBody.addAll, onDone: () {
          String postData = new String.fromCharCodes(postBody);
          print('REST: Received: ${postData}');

          // Decode the JSON
          Map postGame = JSON.decode(postData);

          int id = postGame["id"];

          if (!GameMap.containsKey(id)) {
            // Set the game map to the new Game object

            // Set the communication port
            var sendPort = receivePort.sendPort;
            // Spwan Isolate
            Future<Isolate> remote = Isolate.spawnUri(Uri.parse("websocket.dart"), ["$id"], sendPort);

            var newGame = new Game(id, postGame["title"], postGame["status"], 0);
            GameMap[id] = newGame;
          }

          // TODO lookup from database
          request.response.write(getEncodedGame(id));
          request.response.close();
        });

        break;

      case 'GET':
        List result = request.uri.pathSegments;

        // TODO validation, look for id parameter
        if (result[2] != '') {
          // id parameter
          var id = int.parse(result[2]);

          // TODO lookup from database
          if (GameMap.isNotEmpty && GameMap.containsKey(id)) {
            request.response.write(getEncodedGame(id));
          }
          else {
            request.response.write("{}");
          }
        }
        else {
          if (GameMap.isNotEmpty) {
            var total = GameMap.length;
            var count = 1;

            var jsonoutput = '{ "data": [';

            // Iterate through all the objects
            for (var Game in GameMap.keys) {

              var GameObj = GameMap[Game];
              jsonoutput = jsonoutput +
              '{"id": ${GameObj.id}, "object": "game", "title": "${GameObj.title}", "status": "${GameObj.status}", "port": "${GameObj.port}"}';

              if (count != total) {
                jsonoutput = jsonoutput + ',';
              }
              count++;
            }

            jsonoutput = jsonoutput +  '] }';
            request.response.write(jsonoutput);
          }
          else {
            request.response.write("{}");
          }
        }
        request.response.close();
        break;
      default:
        request.response.statusCode = HttpStatus.METHOD_NOT_ALLOWED;
        request.response.close();
    }
  }
  else {
    request.response.write('Live Games: ${GameMap.length}');
    request.response.close();
  }
}
