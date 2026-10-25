import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

bool get isMobilePlatform => Platform.isIOS || Platform.isAndroid;

String get operatingSystemName => Platform.operatingSystem;

abstract interface class TempAudioDirectory {
  String get path;
  Future<String> writeTempFile(String filename, Uint8List bytes);
  String nextFilePath(String filename);
  void dispose();
}

class _IoTempAudioDirectory implements TempAudioDirectory {
  _IoTempAudioDirectory(this._dir);

  final Directory _dir;

  @override
  String get path => _dir.path;

  @override
  Future<String> writeTempFile(String filename, Uint8List bytes) async {
    final file = File('${_dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    return file.absolute.path;
  }

  @override
  String nextFilePath(String filename) => '${_dir.path}/$filename';

  @override
  void dispose() {
    unawaited(_dir.delete(recursive: true).then((_) {}, onError: (_) {}));
  }
}

Future<TempAudioDirectory> createTempAudioDirectory(String prefix) async {
  final dir = await Directory.systemTemp.createTemp(prefix);
  return _IoTempAudioDirectory(dir);
}

Future<Uint8List?> readFileBytesIfExists(String path) async {
  final file = File(path);
  if (!file.existsSync()) return null;
  return file.readAsBytes();
}

Future<void> deleteFileIfExists(String path) async {
  try {
    final file = File(path);
    if (file.existsSync()) {
      await file.delete();
    }
  } catch (_) {}
}
