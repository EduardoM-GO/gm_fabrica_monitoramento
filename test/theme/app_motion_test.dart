import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_motion.dart';

void main() {
  group('AppMotion Tokens & Widgets', () {
    testWidgets(
      'PressableScale reacts to pointer down and up without blocking taps',
      (WidgetTester tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: PressableScale(
                  onTap: () => tapped = true,
                  child: const Text('Button'),
                ),
              ),
            ),
          ),
        );

        final animatedScaleFinder = find.byType(AnimatedScale);
        expect(animatedScaleFinder, findsOneWidget);

        AnimatedScale scaleWidget = tester.widget<AnimatedScale>(
          animatedScaleFinder,
        );
        expect(scaleWidget.scale, 1.0);

        // Pointer down simulates press
        final gesture = await tester.startGesture(
          tester.getCenter(find.text('Button')),
        );
        await tester.pump();

        scaleWidget = tester.widget<AnimatedScale>(animatedScaleFinder);
        expect(scaleWidget.scale, 0.96);

        // Pointer up simulates release
        await gesture.up();
        await tester.pumpAndSettle();

        scaleWidget = tester.widget<AnimatedScale>(animatedScaleFinder);
        expect(scaleWidget.scale, 1.0);
        expect(tapped, isTrue);
      },
    );

    testWidgets(
      'SlidingCounterText rolls only the changed digit (e.g. 24 -> 25)',
      (WidgetTester tester) async {
        int count = 24;

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: SlidingCounterText(
                    value: count,
                    style: const TextStyle(fontSize: 32),
                  ),
                  floatingActionButton: FloatingActionButton(
                    onPressed: () => setState(() => count = 25),
                  ),
                );
              },
            ),
          ),
        );

        // Value 24: Tens place has '2', units place has '4'
        expect(find.bySemanticsLabel('24'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        expect(find.text('4'), findsOneWidget);

        // Increment 24 -> 25
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pump(); // Deliver tap, starts transition
        await tester.pump(const Duration(milliseconds: 90));

        // Tens digit '2' remains completely stationary (still 1 widget)
        expect(find.text('2'), findsOneWidget);

        // Units digit '4' is exiting while '5' is entering
        expect(find.text('5'), findsOneWidget);

        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('25'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        expect(find.text('5'), findsOneWidget);
        expect(find.text('4'), findsNothing);
      },
    );

    testWidgets('SmoothProgressBar smoothly updates progress value', (
      WidgetTester tester,
    ) async {
      double progress = 0.2;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: SmoothProgressBar(
                  value: progress,
                  progressColor: Colors.blue,
                  backgroundColor: Colors.grey,
                ),
                floatingActionButton: FloatingActionButton(
                  onPressed: () => setState(() => progress = 0.8),
                ),
              );
            },
          ),
        ),
      );

      // Settle initial progress to 0.2
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        closeTo(0.2, 0.001),
      );

      // Trigger update to 0.8
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump(); // Deliver tap and trigger setState
      await tester.pump(const Duration(milliseconds: 120)); // Advance animation

      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      // Progress is smoothly interpolating between 0.2 and 0.8
      expect(indicator.value, greaterThan(0.2));
      expect(indicator.value, lessThan(0.8));

      await tester.pumpAndSettle();
      final finalIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(finalIndicator.value, closeTo(0.8, 0.001));
    });

    testWidgets('BreathingGlow renders and cycles opacity when pulsing', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BreathingGlow(
              isPulsing: true,
              minOpacity: 0.7,
              child: Text('Lote Pronto'),
            ),
          ),
        ),
      );

      expect(find.text('Lote Pronto'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(BreathingGlow),
          matching: find.byType(FadeTransition),
        ),
        findsOneWidget,
      );

      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('Lote Pronto'), findsOneWidget);
    });

    testWidgets('Respects disableAnimations (reduced motion)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: Column(
                children: [
                  PressableScale(child: Text('Reduced Press')),
                  BreathingGlow(child: Text('Reduced Breathe')),
                  SmoothProgressBar(
                    value: 0.5,
                    progressColor: Colors.green,
                    backgroundColor: Colors.black,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // PressableScale does not scale when animations are disabled
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Reduced Press')),
      );
      await tester.pump();
      final scaleWidget = tester.widget<AnimatedScale>(
        find.byType(AnimatedScale),
      );
      expect(scaleWidget.scale, 1.0);
      await gesture.up();

      // BreathingGlow does not mount FadeTransition when disabled
      expect(
        find.descendant(
          of: find.byType(BreathingGlow),
          matching: find.byType(FadeTransition),
        ),
        findsNothing,
      );
    });
  });
}
