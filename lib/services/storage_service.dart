import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;

class StorageService {
  Future<File> _getProjectFile(String projectName) async {
    final directory = await getApplicationDocumentsDirectory();
    // Sanitize the project name for filesystem
    final safeName = projectName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    return File('${directory.path}/$safeName.json');
  }

  Future<void> saveSession(String projectName, Map<String, dynamic> sessionData) async {
    try {
      final file = await _getProjectFile(projectName);
      final jsonStr = jsonEncode(sessionData);
      await file.writeAsString(jsonStr);
    } catch (e) {
      debugPrint("Error saving session: $e");
    }
  }

  Future<Map<String, dynamic>?> loadSession(String projectName) async {
    try {
      final file = await _getProjectFile(projectName);
      if (!await file.exists()) return null;
      
      final jsonStr = await file.readAsString();
      final decoded = jsonDecode(jsonStr);
      
      // Backward compatibility if it was a List
      if (decoded is List) {
         return {'strokes': decoded};
      }
      return decoded as Map<String, dynamic>;
    } catch (e) {
      debugPrint("Error loading session: $e");
      return null;
    }
  }

  Future<List<String>> listProjects() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final List<FileSystemEntity> entities = await directory.list().toList();
      List<String> projects = [];
      for (var entity in entities) {
        if (entity is File && entity.path.endsWith('.json')) {
          final fileName = entity.uri.pathSegments.last;
          projects.add(fileName.replaceAll('.json', ''));
        }
      }
      return projects;
    } catch (e) {
      debugPrint("Error listing projects: $e");
      return [];
    }
  }

  Future<void> deleteProject(String projectName) async {
    try {
      final file = await _getProjectFile(projectName);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint("Error deleting project: $e");
    }
  }

  Future<String?> saveImageToGallery(ui.Image image) async {
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;
      final buffer = byteData.buffer;

      Directory? dir;
      if (Platform.isAndroid) {
        dir = await getExternalStorageDirectory();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      if (dir != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final file = File('${dir.path}/easy_drawing_$timestamp.png');
        await file.writeAsBytes(buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
        return file.path;
      }
    } catch (e) {
      debugPrint("Error saving image: $e");
    }
    return null;
  }
}
