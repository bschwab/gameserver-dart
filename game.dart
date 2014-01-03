
part of gameserver;

// Game Object
class Game {
  final int id;         // Game Id
  final String title;   // Game Title
  final String status;  // Game Status
  int port;             // Game Isolate Port
  DateTime timestamp;   // Timestamp of creation
  var sendPort;         // SendPort for main thread

  Game(this.id, this.title, this.status, this.port);
}
