import 'dart:typed_data';

bool get isMobilePlatform => false;

String get operatingSystemName => 'web';

abstract interface class TempAudioDirectory {
  String get path;
  Future<String> writeTempFile(String filename, Uint8List bytes);
  String nextFilePath(String filename);
  void dispose();
}

Future<TempAudioDirectory> createTempAudioDirectory(String prefix) async {
  throw UnsupportedError('Temporary filesystem directories are not supported on Web.');
}

Future<Uint8List?> readFileBytesIfExists(String path) async => null;

Future<void> deleteFileIfExists(String path) async {}
