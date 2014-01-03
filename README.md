Dart Game Server
=================

A Game Server written in Dart.

This has a main thread that handles REST calls.

Games are created with a POST to the REST endpoint, for example: http://localhost:8000/v1/games/
{ "id": 13, "object": "game", "title": "game title", "status": "live" }

The REST server will then fork off an Isolate and store the port it is listening on for future Websocket connections.

You can then query the Game object:
GET http://localhost:8000/v1/games/13
{
    "id": 13,
    "object": "game",
    "title": "game title",
    "status": "live",
    "port": "57880"
}

Or list all Games:
GET http://localhost:8000/v1/games/
{
    "data": [
        {
            "id": 13,
            "object": "game",
            "title": "game title",
            "status": "live",
            "port": "57880"
        }
    ]
}

Clients can then connect via Websocket to this port: ws://localhost:57880/connect
All communication on this connection will be broadcast to all other clients.

Example:
SENT: hello!
RESPONSE: socket : hello!
RESPONSE: socket : how are you?

The main thread also sends off an example ping message, which gets broadcast to all clients as well:
RESPONSE: {"type":"ping","date":1388728858}

### v0.1 
Initial skeleton

### Feedback

Feedback and contributions are welcome!
