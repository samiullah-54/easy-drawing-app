import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import '../state/drawing_state.dart';
import 'package:network_info_plus/network_info_plus.dart';

class ServerService {
  static final ServerService _instance = ServerService._internal();
  factory ServerService() => _instance;
  ServerService._internal();

  HttpServer? _server;
  final List<WebSocket> _sockets = [];
  bool get isRunning => _server != null;

  Future<String?> getWifiIP() async {
    final info = NetworkInfo();
    return await info.getWifiIP();
  }

  Future<void> startServer(DrawingState state) async {
    if (isRunning) return;
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
      debugPrint("Server running on port 8080");

      _server!.listen((HttpRequest request) async {
        if (request.uri.path == '/') {
          request.response
            ..headers.contentType = ContentType.html
            ..write(_htmlClient)
            ..close();
        } else if (request.uri.path == '/ws') {
          final socket = await WebSocketTransformer.upgrade(request);
          _sockets.add(socket);
          
          socket.add(jsonEncode({
            'type': 'sync',
            'strokes': state.strokes.map((s) => s.toJson()).toList(),
            'objects': state.objects.map((o) => o.toJson()).toList()
          }));

          socket.listen((message) {
            // Ignore incoming messages for now
          }, onDone: () {
            _sockets.remove(socket);
          });
        } else {
          request.response
            ..statusCode = HttpStatus.notFound
            ..close();
        }
      });
    } catch (e) {
      debugPrint("Server error: $e");
    }
  }

  void stopServer() {
    for (var socket in _sockets) {
      socket.close();
    }
    _sockets.clear();
    _server?.close();
    _server = null;
  }

  void broadcastStartStroke(DrawingStroke stroke) {
    _broadcast({'type': 'start', 'stroke': stroke.toJson()});
  }

  void broadcastMoveStroke(Offset point) {
    _broadcast({'type': 'move', 'point': {'dx': point.dx, 'dy': point.dy}});
  }

  void broadcastEndStroke() {
    _broadcast({'type': 'end'});
  }

  void broadcastClear() {
    _broadcast({'type': 'clear'});
  }

  void broadcastUndo() {
    _broadcast({'type': 'undo'});
  }
  
  void broadcastSync(DrawingState state) {
    _broadcast({
      'type': 'sync',
      'strokes': state.strokes.map((s) => s.toJson()).toList(),
      'objects': state.objects.map((o) => o.toJson()).toList()
    });
  }

  void _broadcast(Map<String, dynamic> data) {
    if (_sockets.isEmpty) return;
    final jsonStr = jsonEncode(data);
    for (var socket in _sockets) {
      socket.add(jsonStr);
    }
  }

  final String _htmlClient = '''
<!DOCTYPE html>
<html>
<head>
    <title>Easy Drawing Cast</title>
    <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
    <link href="https://fonts.googleapis.com/icon?family=Material+Icons+Outlined" rel="stylesheet">
    <style>
        body { margin: 0; padding: 0; overflow: hidden; background: #333333; display: flex; justify-content: center; align-items: center; height: 100vh;}
        canvas { display: block; background: #ffffff; box-shadow: 0 0 30px rgba(0,0,0,0.5); transform-origin: center center; }
        #status { position: absolute; top: 10px; left: 10px; background: rgba(0,0,0,0.6); color: white; padding: 8px 12px; border-radius: 6px; font-family: sans-serif; z-index: 10; font-size: 14px;}
    </style>
</head>
<body>
    <div id="status">Connecting to Phone...</div>
    <canvas id="canvas"></canvas>
    <script>
        const canvas = document.getElementById('canvas');
        // Fixed virtual canvas resolution
        canvas.width = 1920;
        canvas.height = 1080;
        const ctx = canvas.getContext('2d');
        const status = document.getElementById('status');
        
        let strokes = [];
        let objects = [];
        let currentStroke = null;

        function resize() {
            // Scale canvas CSS to fit window while preserving 16:9 aspect ratio
            const scale = Math.min(window.innerWidth / 1920, window.innerHeight / 1080) * 0.95; // 0.95 for tiny margin
            canvas.style.transform = `scale(\${scale})`;
        }
        window.addEventListener('resize', resize);
        resize();

        function redraw() {
            ctx.clearRect(0, 0, canvas.width, canvas.height);
            for (const s of strokes) { drawStroke(s); }
            if (currentStroke) { drawStroke(currentStroke); }
            for (const o of objects) { drawObject(o); }
        }

        function drawObject(o) {
            ctx.save();
            ctx.translate(o.position.dx, o.position.dy);
            ctx.rotate(o.rotation);
            ctx.scale(o.scale, o.scale);
            
            const colorVal = o.color;
            const a = ((colorVal >>> 24) & 0xFF) / 255.0;
            const r = (colorVal >>> 16) & 0xFF;
            const g = (colorVal >>> 8) & 0xFF;
            const b = colorVal & 0xFF;
            ctx.fillStyle = `rgba(\${r}, \${g}, \${b}, \${a})`;
            
            ctx.font = '48px "Material Icons"';
            ctx.textAlign = 'center';
            ctx.textBaseline = 'middle';
            ctx.fillText(String.fromCodePoint(o.iconCodePoint), 0, 0);
            
            ctx.restore();
        }

        function drawStroke(s) {
            if (!s.points || s.points.length < 2) return;
            ctx.beginPath();
            
            const colorVal = s.color;
            const a = ((colorVal >>> 24) & 0xFF) / 255.0;
            const r = (colorVal >>> 16) & 0xFF;
            const g = (colorVal >>> 8) & 0xFF;
            const b = colorVal & 0xFF;
            
            ctx.lineWidth = s.strokeWidth;
            ctx.lineCap = 'round';
            ctx.lineJoin = 'round';
            ctx.globalCompositeOperation = 'source-over';
            
            if (s.isEraser) {
                // White pen eraser mode for absolute reliability
                ctx.strokeStyle = 'rgba(255,255,255,1)';
            } else {
                ctx.strokeStyle = `rgba(\${r}, \${g}, \${b}, \${a})`;
            }

            ctx.moveTo(s.points[0].dx, s.points[0].dy);
            for (let i = 1; i < s.points.length; i++) {
                ctx.lineTo(s.points[i].dx, s.points[i].dy);
            }
            ctx.stroke();
        }

        function connect() {
            const ws = new WebSocket(`ws://\${window.location.host}/ws`);
            
            ws.onopen = () => { status.innerText = 'Connected: Live View'; status.style.background = 'rgba(0,128,0,0.6)'; };
            ws.onclose = () => { status.innerText = 'Disconnected. Reconnecting...'; status.style.background = 'rgba(255,0,0,0.6)'; setTimeout(connect, 2000); };
            
            ws.onmessage = (event) => {
                const msg = JSON.parse(event.data);
                if (msg.type === 'sync') {
                    strokes = msg.strokes;
                    objects = msg.objects;
                    currentStroke = null;
                    redraw();
                } else if (msg.type === 'start') {
                    currentStroke = msg.stroke;
                    redraw();
                } else if (msg.type === 'move') {
                    if (currentStroke) {
                        currentStroke.points.push(msg.point);
                        redraw();
                    }
                } else if (msg.type === 'end') {
                    if (currentStroke) {
                        strokes.push(currentStroke);
                        currentStroke = null;
                        redraw();
                    }
                } else if (msg.type === 'clear') {
                    strokes = [];
                    objects = [];
                    currentStroke = null;
                    redraw();
                } else if (msg.type === 'undo') {
                    strokes.pop();
                    currentStroke = null;
                    redraw();
                }
            };
        }
        connect();
    </script>
</body>
</html>
  ''';
}
