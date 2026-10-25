/// Picks a real camera backend when the plugin is linked, otherwise stub.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show MissingPluginException;

import '../camera/camera_runtime.dart';
import 'camera_runtime_impl.dart';
import 'camera_runtime_stub.dart';

Future<ConsonaCameraRuntime> createConsonaCameraRuntime() async {
  try {
    final runtime = ConsonaCameraRuntimeImpl();
    await runtime.availableLenses();
    return runtime;
  } on MissingPluginException catch (e) {
    debugPrint(
      'createConsonaCameraRuntime: camera plugin missing ($e) — using stub.',
    );
    return ConsonaCameraRuntimeStub();
  } catch (e) {
    debugPrint('createConsonaCameraRuntime: probe note: $e');
    return ConsonaCameraRuntimeImpl();
  }
}
