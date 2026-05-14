import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/storage_service.dart';
import '../services/server_service.dart';

enum DrawingTool { pen, eraser, pan }

class DrawingStroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final bool isEraser;

  DrawingStroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.isEraser,
  });

  Map<String, dynamic> toJson() {
    return {
      'points': points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
      'color': color.toARGB32(),
      'strokeWidth': strokeWidth,
      'isEraser': isEraser,
    };
  }

  factory DrawingStroke.fromJson(Map<String, dynamic> json) {
    var pointsList = json['points'] as List;
    List<Offset> parsedPoints = pointsList.map((p) => Offset(p['dx'], p['dy'])).toList();
    
    return DrawingStroke(
      points: parsedPoints,
      color: Color(json['color']),
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      isEraser: json['isEraser'],
    );
  }
}

class CanvasObject {
  final String id;
  final IconData icon;
  final Offset position;
  final double scale;
  final double rotation;
  final Color color;

  CanvasObject({
    required this.id,
    required this.icon,
    required this.position,
    required this.scale,
    required this.rotation,
    required this.color,
  });

  CanvasObject copyWith({
    Offset? position,
    double? scale,
    double? rotation,
    Color? color,
  }) {
    return CanvasObject(
      id: id,
      icon: icon,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'iconFontPackage': icon.fontPackage,
      'position': {'dx': position.dx, 'dy': position.dy},
      'scale': scale,
      'rotation': rotation,
      'color': color.toARGB32(),
    };
  }

  factory CanvasObject.fromJson(Map<String, dynamic> json) {
    return CanvasObject(
      id: json['id'],
      icon: IconData(
        json['iconCodePoint'],
        fontFamily: json['iconFontFamily'],
        fontPackage: json['iconFontPackage'],
      ),
      position: Offset(json['position']['dx'], json['position']['dy']),
      scale: (json['scale'] as num).toDouble(),
      rotation: (json['rotation'] as num).toDouble(),
      color: Color(json['color']),
    );
  }
}

class DrawingState extends ChangeNotifier {
  List<DrawingStroke> strokes = [];
  List<CanvasObject> objects = [];
  List<DrawingStroke> redoStack = [];
  List<CanvasObject> objectsRedoStack = [];
  
  DrawingTool selectedTool = DrawingTool.pen;
  Color selectedColor = Colors.black;
  double strokeWidth = 5.0;

  final String projectName;
  final StorageService _storageService = StorageService();
  bool isLoading = true;

  DrawingState(this.projectName) {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final loadedData = await _storageService.loadSession(projectName);
    if (loadedData != null) {
      if (loadedData.containsKey('strokes')) {
        strokes = (loadedData['strokes'] as List).map((s) => DrawingStroke.fromJson(s)).toList();
      }
      if (loadedData.containsKey('objects')) {
        objects = (loadedData['objects'] as List).map((o) => CanvasObject.fromJson(o)).toList();
      }
    }
    isLoading = false;
    notifyListeners();
  }

  void saveProject() {
    final sessionData = {
      'strokes': strokes.map((s) => s.toJson()).toList(),
      'objects': objects.map((o) => o.toJson()).toList(),
    };
    _storageService.saveSession(projectName, sessionData);
  }

  void addStroke(DrawingStroke stroke) {
    strokes.add(stroke);
    redoStack.clear();
    notifyListeners();
    ServerService().broadcastStartStroke(stroke);
  }

  void updateCurrentStroke(Offset point) {
    if (strokes.isNotEmpty) {
      strokes.last.points.add(point);
      notifyListeners();
      ServerService().broadcastMoveStroke(point);
    }
  }

  void endStroke() {
     ServerService().broadcastEndStroke();
  }

  void undo() {
    if (strokes.isNotEmpty) {
      redoStack.add(strokes.removeLast());
      notifyListeners();
      ServerService().broadcastUndo();
    }
  }

  void redo() {
    if (redoStack.isNotEmpty) {
      strokes.add(redoStack.removeLast());
      notifyListeners();
      ServerService().broadcastSync(this); // Redo is complex incrementally, just sync
    }
  }

  void clearCanvas() {
    strokes.clear();
    objects.clear();
    redoStack.clear();
    objectsRedoStack.clear();
    notifyListeners();
    ServerService().broadcastClear();
  }

  // Object management
  void addObject(IconData icon) {
    final newObj = CanvasObject(
      id: const Uuid().v4(),
      icon: icon,
      position: const Offset(960, 540), // Center of 1920x1080 canvas
      scale: 3.0,
      rotation: 0.0,
      color: selectedColor,
    );
    objects.add(newObj);
    objectsRedoStack.clear();
    notifyListeners();
    ServerService().broadcastSync(this);
  }

  void updateObject(CanvasObject updatedObj) {
    final index = objects.indexWhere((o) => o.id == updatedObj.id);
    if (index != -1) {
      objects[index] = updatedObj;
      notifyListeners();
      ServerService().broadcastSync(this);
    }
  }

  void removeObject(String id) {
    objects.removeWhere((o) => o.id == id);
    notifyListeners();
    ServerService().broadcastSync(this);
  }

  void setTool(DrawingTool tool) {
    selectedTool = tool;
    notifyListeners();
  }

  void setColor(Color color) {
    selectedColor = color;
    notifyListeners();
  }

  void setStrokeWidth(double width) {
    strokeWidth = width;
    notifyListeners();
  }
}
