import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tikli/core/map/map_interaction_options.dart';

void main() {
  group('northUpInteractionOptions', () {
    test('disables gesture rotation', () {
      expect(
        InteractiveFlag.hasRotate(northUpInteractionOptions.flags),
        isFalse,
      );
    });

    test('keeps pan and zoom gestures enabled', () {
      final flags = northUpInteractionOptions.flags;
      expect(InteractiveFlag.hasDrag(flags), isTrue);
      expect(InteractiveFlag.hasPinchZoom(flags), isTrue);
      expect(InteractiveFlag.hasDoubleTapZoom(flags), isTrue);
      expect(InteractiveFlag.hasScrollWheelZoom(flags), isTrue);
    });

    test('disables Ctrl + drag rotation', () {
      final isKeyTrigger =
          northUpInteractionOptions.cursorKeyboardRotationOptions.isKeyTrigger;
      expect(isKeyTrigger, isNotNull);
      for (final key in CursorKeyboardRotationOptions.defaultTriggerKeys) {
        expect(isKeyTrigger!(key), isFalse, reason: key.debugName);
      }
      expect(isKeyTrigger!(LogicalKeyboardKey.controlLeft), isFalse);
    });
  });
}
