// Shared map interaction settings used by every map in the app.

import 'package:flutter_map/flutter_map.dart';

/// Map interaction that keeps the map fixed north-up.
///
/// Disables rotation by touch gesture ([InteractiveFlag.rotate]) and by
/// Ctrl + mouse drag on desktop/web, which flutter_map handles separately
/// through [CursorKeyboardRotationOptions].
final InteractionOptions northUpInteractionOptions = InteractionOptions(
  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
  cursorKeyboardRotationOptions: CursorKeyboardRotationOptions.disabled(),
);
