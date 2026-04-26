import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_runners/flutter_test_runners.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_editor/super_editor_test.dart';
import 'package:super_editor/super_test.dart';

void main() {
  group('Scribble', () {
    group('state tracking', () {
      testWidgetsOnIos('tracks scribble in-progress via insertTextPlaceholder and removeTextPlaceholder',
          (tester) async {
        await tester //
            .createDocument()
            .withSingleEmptyParagraph()
            .withInputSource(TextInputSource.ime)
            .pump();

        // Place the caret so the IME connects.
        await tester.placeCaretInParagraph('1', 0);

        // Simulate the platform calling insertTextPlaceholder (Scribble start).
        await _sendScribbleInsertPlaceholder(tester, const Size(20, 20));

        // Pump to let the frame callback run.
        await tester.pump();

        // Simulate the platform calling removeTextPlaceholder (Scribble end).
        await _sendScribbleRemovePlaceholder(tester);
        await tester.pump();
      });

      testWidgetsOnAndroid('tracks scribble in-progress via insertTextPlaceholder and removeTextPlaceholder',
          (tester) async {
        await tester //
            .createDocument()
            .withSingleEmptyParagraph()
            .withInputSource(TextInputSource.ime)
            .pump();

        // Place the caret so the IME connects.
        await tester.placeCaretInParagraph('1', 0);

        // Simulate the platform calling insertTextPlaceholder (Scribble start).
        await _sendScribbleInsertPlaceholder(tester, const Size(20, 20));
        await tester.pump();

        // Simulate the platform calling removeTextPlaceholder (Scribble end).
        await _sendScribbleRemovePlaceholder(tester);
        await tester.pump();
      });
    });

    group('IME text input during scribble', () {
      testWidgetsOnIos('applies text deltas during scribble', (tester) async {
        final document = MutableDocument(
          nodes: [
            ParagraphNode(id: '1', text: AttributedText('Hello')),
          ],
        );

        await tester //
            .createDocument()
            .withCustomContent(document)
            .withInputSource(TextInputSource.ime)
            .pump();

        // Place caret at end of text.
        await tester.placeCaretInParagraph('1', 5);

        // Start a scribble interaction.
        await _sendScribbleInsertPlaceholder(tester, const Size(20, 20));
        await tester.pump();

        // Type text via IME (simulating scribble-converted text).
        await tester.typeImeText(' world');

        // Verify text was inserted.
        expect(
          (document.getNodeAt(0)! as ParagraphNode).text.toPlainText(),
          'Hello world',
        );

        // End scribble.
        await _sendScribbleRemovePlaceholder(tester);
        await tester.pump();
      });
    });
  });
}

/// Simulates the platform sending `TextInputClient.insertTextPlaceholder` to the
/// Flutter engine, which happens when a Scribble interaction begins.
Future<void> _sendScribbleInsertPlaceholder(WidgetTester tester, Size size) async {
  await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
    SystemChannels.textInput.name,
    SystemChannels.textInput.codec.encodeMethodCall(
      MethodCall(
        'TextInputClient.insertTextPlaceholder',
        [-1, size.width, size.height],
      ),
    ),
    null,
  );
}

/// Simulates the platform sending `TextInputClient.removeTextPlaceholder` to the
/// Flutter engine, which happens when a Scribble interaction ends.
Future<void> _sendScribbleRemovePlaceholder(WidgetTester tester) async {
  await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
    SystemChannels.textInput.name,
    SystemChannels.textInput.codec.encodeMethodCall(
      const MethodCall(
        'TextInputClient.removeTextPlaceholder',
        [-1],
      ),
    ),
    null,
  );
}
