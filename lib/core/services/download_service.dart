import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'dart:async';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';

// Top-Level Callback (Must be outside class)
@pragma('vm:entry-point')
void downloadCallback(String id, int status, int progress) {
  final SendPort? send = IsolateNameServer.lookupPortByName('downloader_send_port');
  send?.send([id, status, progress]);
}

class DownloadService {
  static const String _portName = 'downloader_send_port';
  static final ReceivePort _port = ReceivePort();
  static final Map<String, Function(int, int)> _callbacks = {};

  static void init() {
    if (!Platform.isAndroid) return; // iOS bypass

    IsolateNameServer.removePortNameMapping(_portName);
    IsolateNameServer.registerPortWithName(_port.sendPort, _portName);

    _port.listen((dynamic data) {
      String id = data[0];
      int status = data[1];
      int progress = data[2];

      if (_callbacks.containsKey(id)) {
        _callbacks[id]!(progress, status);
      }
    });

    FlutterDownloader.registerCallback(downloadCallback);
  }

  static Future<String?> downloadApk({
    required String url,
    required String fileName,
    required String packageName,
    required Function(int, DownloadTaskStatus) onProgress,
  }) async {
    if (!Platform.isAndroid) return null; // iOS bypass

    if (await Permission.notification.isDenied) await Permission.notification.request();
    var storage = await Permission.storage.status;
    if (!storage.isGranted) await Permission.storage.request();
    if (await Permission.requestInstallPackages.isDenied) await Permission.requestInstallPackages.request();

    final directory = await getExternalStorageDirectory();
    if (directory == null) return null;
    final savePath = directory.path;
    final filePath = '$savePath/$fileName';

    final file = File(filePath);
    if (await file.exists()) await file.delete();

    try {
      final taskId = await FlutterDownloader.enqueue(
        url: url,
        savedDir: savePath,
        fileName: fileName,
        showNotification: true,
        openFileFromNotification: true,
        saveInPublicStorage: false,
      );

      if (taskId != null) {
        _callbacks[taskId] = (prog, statInt) {
          final statusEnum = DownloadTaskStatus.values[statInt];
          onProgress(prog, statusEnum);

          if (statusEnum == DownloadTaskStatus.complete || statusEnum == DownloadTaskStatus.failed) {
            _callbacks.remove(taskId);
          }
        };
      }
      return taskId;
    } catch (e) {
      print("Download Error: $e");
      return null;
    }
  }

  static Future<String?> getDownloadedFilePath(String taskId) async {
    if (!Platform.isAndroid) return null; // iOS bypass

    final tasks = await FlutterDownloader.loadTasks();
    if (tasks == null) return null;
    try {
      final task = tasks.firstWhere((t) => t.taskId == taskId);
      if (task.status == DownloadTaskStatus.complete) {
        return '${task.savedDir}/${task.filename}';
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  static Future<void> deleteApk(String fileName) async {
    if (!Platform.isAndroid) return; // iOS bypass

    final directory = await getExternalStorageDirectory();
    if (directory != null) {
      final file = File('${directory.path}/$fileName');
      if (await file.exists()) await file.delete();
    }
  }

  static Future<void> cancelDownload(String taskId) async {
    if (!Platform.isAndroid) return; // iOS bypass

    await FlutterDownloader.cancel(taskId: taskId);
    _callbacks.remove(taskId);
  }

  static Future<bool> installApk(String filePath) async {
    if (!Platform.isAndroid) return false; // iOS bypass

    final result = await OpenFilex.open(filePath);
    return result.type == ResultType.done;
  }
}