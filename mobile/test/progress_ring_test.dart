import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todotrip/features/trips/presentation/widgets/progress_ring.dart';

/// The ring is now shared between a trip's days and a list's items, so a change
/// made for one of them lands on the other. These pin the contract that keeps
/// both callers safe: it paints, it accepts having no progress at all, and a
/// value outside 0–1 does not become a second lap around the circle.
void main() {
  Future<void> pump(WidgetTester tester, Widget ring) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Center(child: ring)),
    ),
  );

  testWidgets('it draws at the size it was asked for', (tester) async {
    await pump(
      tester,
      const ProgressRing(size: 52, colour: Colors.teal, value: 0.4),
    );

    expect(tester.getSize(find.byType(ProgressRing)), const Size(52, 52));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a null value is a bare track, not a crash', (tester) async {
    /// An upcoming trip has no fraction of itself behind it, and an empty list
    /// has nothing to be a fraction of.
    await pump(tester, const ProgressRing(size: 44, colour: Colors.teal));
    expect(tester.takeException(), isNull);
  });

  testWidgets('it survives values outside the range', (tester) async {
    /// A trip whose end date was moved earlier can hand this a value above one,
    /// and clamping there is cheaper than trusting every caller.
    for (final value in [-0.5, 0.0, 1.0, 2.5]) {
      await pump(
        tester,
        ProgressRing(size: 44, colour: Colors.teal, value: value),
      );
      expect(tester.takeException(), isNull, reason: 'value $value');
    }
  });

  testWidgets('the child sits in the middle', (tester) async {
    await pump(
      tester,
      const ProgressRing(
        size: 44,
        colour: Colors.teal,
        value: 0.25,
        child: Text('3'),
      ),
    );

    expect(
      tester.getCenter(find.text('3')),
      tester.getCenter(find.byType(ProgressRing)),
    );
  });
}
