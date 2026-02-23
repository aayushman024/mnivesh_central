import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_riverpod/legacy.dart';

// Download state for a specific app
class DownloadState {
  final String? taskId;
  final int progress;
  final DownloadTaskStatus status;
  final String? filePath;

  const DownloadState({
    this.taskId,
    this.progress = 0,
    this.status = DownloadTaskStatus.undefined,
    this.filePath,
  });

  bool get isDownloading =>
      status == DownloadTaskStatus.running || status == DownloadTaskStatus.enqueued;
  bool get isPaused => status == DownloadTaskStatus.paused;
  bool get isComplete => status == DownloadTaskStatus.complete;
  bool get isFailed => status == DownloadTaskStatus.failed;
  bool get isCanceled => status == DownloadTaskStatus.canceled;

  DownloadState copyWith({
    String? taskId,
    int? progress,
    DownloadTaskStatus? status,
    String? filePath,
  }) {
    return DownloadState(
      taskId: taskId ?? this.taskId,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      filePath: filePath ?? this.filePath,
    );
  }
}

// State notifier for managing downloads
class DownloadStateNotifier extends StateNotifier<Map<String, DownloadState>> {
  DownloadStateNotifier() : super({});

  void updateDownload(String packageName, DownloadState downloadState) {
    state = {
      ...state,
      packageName: downloadState,
    };
  }

  void removeDownload(String packageName) {
    final newState = Map<String, DownloadState>.from(state);
    newState.remove(packageName);
    state = newState;
  }

  void updateProgress(String packageName, int progress, DownloadTaskStatus status) {
    if (state.containsKey(packageName)) {
      state = {
        ...state,
        packageName: state[packageName]!.copyWith(
          progress: progress,
          status: status,
        ),
      };
    }
  }

  void setFilePath(String packageName, String filePath) {
    if (state.containsKey(packageName)) {
      state = {
        ...state,
        packageName: state[packageName]!.copyWith(filePath: filePath),
      };
    }
  }

  DownloadState? getDownloadState(String packageName) {
    return state[packageName];
  }
}

// Provider for download states
final downloadStateProvider =
StateNotifierProvider<DownloadStateNotifier, Map<String, DownloadState>>(
      (ref) => DownloadStateNotifier(),
);