import 'package:flutter_test/flutter_test.dart';
import 'package:consona_flutter/consona_flutter.dart';

class CounterState {
  const CounterState(this.count);
  final int count;
}

class CounterEngine extends ConsonaEngine<CounterState> {
  CounterEngine() : super(const CounterState(0));

  void increment() {
    setState((prev) => CounterState(prev.count + 1));
  }

  void addBatch(int a, int b) {
    batch(() {
      setState((prev) => CounterState(prev.count + a));
      setState((prev) => CounterState(prev.count + b));
    });
  }
}

void main() {
  group('ConsonaEngine', () {
    test('initializes with given initial state', () {
      final engine = CounterEngine();
      expect(engine.state.count, equals(0));
    });

    test('notifies listeners on state change', () {
      final engine = CounterEngine();
      int callCount = 0;
      final cancel = engine.subscribe(() {
        callCount++;
      });

      engine.increment();
      expect(engine.state.count, equals(1));
      expect(callCount, equals(1));

      cancel();
      engine.increment();
      expect(engine.state.count, equals(2));
      expect(callCount, equals(1));
    });

    test('batches state updates into a single notification', () {
      final engine = CounterEngine();
      int callCount = 0;
      engine.subscribe(() => callCount++);

      engine.addBatch(2, 3);
      expect(engine.state.count, equals(5));
      expect(callCount, equals(1));
    });
  });
}
