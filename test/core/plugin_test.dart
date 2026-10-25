import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:consona_flutter/consona_flutter.dart';

class SampleEngine {
  final String name = 'sample';
}

class PluginA extends ConsonaPlugin {
  bool attached = false;
  bool detached = false;

  @override
  String get id => 'plugin.a';

  @override
  FutureOr<void> onAttach(ConsonaRegistry registry) {
    attached = true;
    registry.registerEngine(SampleEngine());
  }

  @override
  FutureOr<void> onDetach() {
    detached = true;
  }
}

class PluginB extends ConsonaPlugin {
  bool attached = false;
  bool detached = false;

  @override
  String get id => 'plugin.b';

  @override
  Set<String> get dependsOn => {'plugin.a'};

  @override
  FutureOr<void> onAttach(ConsonaRegistry registry) {
    // Requires engine from PluginA
    registry.requireEngine<SampleEngine>();
    attached = true;
  }

  @override
  FutureOr<void> onDetach() {
    detached = true;
  }
}

class CyclicPlugin1 extends ConsonaPlugin {
  @override
  String get id => 'cyclic.1';
  @override
  Set<String> get dependsOn => {'cyclic.2'};
  @override
  void onAttach(ConsonaRegistry registry) {}
}

class CyclicPlugin2 extends ConsonaPlugin {
  @override
  String get id => 'cyclic.2';
  @override
  Set<String> get dependsOn => {'cyclic.1'};
  @override
  void onAttach(ConsonaRegistry registry) {}
}

void main() {
  group('ConsonaPlugin & Registry', () {
    test('sorts plugins in topological order', () {
      final a = PluginA();
      final b = PluginB();
      // Pass in reverse dependency order
      final sorted = ConsonaPluginRegistry.sortPlugins([b, a]);
      expect(sorted.first.id, equals('plugin.a'));
      expect(sorted.last.id, equals('plugin.b'));
    });

    test('detects circular dependencies and throws StateError', () {
      expect(
        () => ConsonaPluginRegistry.sortPlugins([CyclicPlugin1(), CyclicPlugin2()]),
        throwsA(isA<StateError>()),
      );
    });

    test('attaches plugins and exposes registered engines', () async {
      final registry = ConsonaPluginRegistry();
      final a = PluginA();
      final b = PluginB();

      await registry.attachAll([b, a]);

      expect(a.attached, isTrue);
      expect(b.attached, isTrue);
      expect(registry.engine<SampleEngine>(), isNotNull);
      expect(registry.requireEngine<SampleEngine>().name, equals('sample'));

      await registry.detachAll();
      expect(a.detached, isTrue);
      expect(b.detached, isTrue);
      expect(registry.engine<SampleEngine>(), isNull);
    });
  });
}
