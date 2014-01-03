
import "dart:async";
import "dart:io";
import "dart:isolate";

final ws_prefix = "/connect";

var port = 0;

List<WebSocket> connections = new List<WebSocket>();

// Websocket handler
class ConnectionsHandler {

  void onConnection(WebSocket conn, HttpRequest req) {
    print('Isolate ${port}: Got a new connection!');
    connections.add(conn);

    conn.listen(
      (message) {
        print('Isolate ${port}: Got message: $message');

        // Broadcast to all in the list
        for (var client in connections) {
            client.add('socket : $message');
          }
        },
        onDone: () => connections.remove(conn),
        onError: (e) => connections.remove(conn)
    );
  }
}

// Listener for the socket
socketListener(request) {
  var connHandler = new ConnectionsHandler();

  if (request.uri.path == ws_prefix) {
    WebSocketTransformer.upgrade(request).then((WebSocket websocket) {
      connHandler.onConnection(websocket, request);
    });
    return;
  }
  else {
    request.response.statusCode = HttpStatus.METHOD_NOT_ALLOWED;
    request.response.close();
  }
}

main(args, mainPort) {

  var serverName = args.length > 0 ? args[0] : "Error";

  HttpServer.bind(InternetAddress.ANY_IP_V4, 0).then((server) {
    server.listen(socketListener);

    if (mainPort != null) {
      var wsPort = new RawReceivePort();

      // Handle receiving messages from the main thread here
      wsPort.handler = (message) {
        // Send message to all connected clients
        for (var client in connections) {
          client.add(message);
        }
      };
      // Report back to the main thread
      mainPort.send([serverName, server.port, wsPort.sendPort]);
    }
    port = server.port;
    print("Isolate: '${serverName}' listening on port ${port}");
  });
}
