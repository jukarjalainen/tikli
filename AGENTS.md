# AI Coding Agent Instructions for Tikli

## Persona & Context
- You are an expert Flutter/Dart engineer specialized in Clean Architecture and responsive UI.
- Goal: Generate code that is production-ready, highly modular, and follows the latest Flutter 3.x standards.
- Always prioritize "Composition over Inheritance."

## Project Overview
This is a cross-platform Flutter application named "tikli" using Flutter 3.7+ with Dart. It's a standard Flutter project supporting Android, iOS, Web, Windows, Linux, and macOS platforms.

## Purpose and core features of the application
- Keep track of bird observations
- There are two permanent lists and observation types: yearly (Vuodenpinnat) and all time (Elämänpinnat)
- Every other list is a custom list the user names, e.g. "Pihapinna" or "Mökki"
- Every list has its own species list
- Observations can be seen on a obervation map
- When the year change, a new yearly list is started
- A single species is a one point in a list, do not count same species twice.
- The observation lists can be outputted as a text and json files
- Custom lists are added from the observation form ("Lisää uusi")


## Architecture & Structure
- **Main entry**: `lib/main.dart` - Standard Flutter app with MaterialApp and counter demo
- **Testing**: `test/widget_test.dart` - Widget tests using `flutter_test`
- **Platform targets**: All platforms configured (android/, ios/, web/, windows/, linux/, macos/)
- **Package**: `com.example.tikli` (Android namespace) - should be updated for production

## Development Workflows

### Build & Run Commands
```bash
# Development
flutter run                    # Hot reload development
flutter run -d chrome         # Web development
flutter run -d windows        # Windows desktop

# Production builds
flutter build apk             # Android APK
flutter build appbundle       # Android App Bundle  
flutter build ios             # iOS (requires macOS/Xcode)
flutter build web             # Web deployment
flutter build windows         # Windows executable
```

### Testing & Analysis
```bash
flutter test                   # Run all tests
flutter analyze               # Static analysis
flutter doctor                # Environment check
```

## Code Conventions & Patterns

### State Management
- Currently uses StatefulWidget pattern with `setState()`
- Follow Flutter's standard state management for simple counters/forms
- Consider  Bloc for state

### Widget Structure
- Prefer `const` constructors: `const MyWidget({super.key})`
- Use `super.key` pattern for widget keys
- Material Design 3 with `ColorScheme.fromSeed()`
- Break down large `build` methods into smaller, reusable widgets rather than helper methods.
- Use `SizedBox` for spacing instead of `Padding` when only a fixed gap is needed.
- All widgets should accept a `Key? key` in their constructor.

### File Organization
- `lib/main.dart` - App entry point and root widget
- `lib/` - All Dart source code
- `test/` - Widget and unit tests
- Assets defined in `pubspec.yaml` (currently none configured)

## Dependencies & Configuration

### Current Dependencies
- `flutter` (SDK)
- `cupertino_icons: ^1.0.8` - iOS-style icons
- `flutter_lints: ^5.0.0` - Recommended lints (dev)

### Linting
- Uses `package:flutter_lints/flutter.yaml` standard rules
- Configured in `analysis_options.yaml`
- Uncomment rules like `prefer_single_quotes: true` to enable

### Adding Dependencies
```yaml
# In pubspec.yaml under dependencies:
http: ^1.1.0                   # HTTP requests
provider: ^6.0.0               # State management
```

## Platform-Specific Notes

### Android
- Namespace: `com.example.tikli` (update for production)
- Min SDK: Uses Flutter default
- Kotlin DSL build files (.gradle.kts)
- Target SDK: Uses Flutter recommendations

### iOS
- Uses Swift for native code
- Standard Flutter iOS configuration
- Asset catalogs in `ios/Runner/Assets.xcassets/`

### Web
- Standard web configuration
- Favicon and icons in `web/` directory
- Manifest for PWA support

## Key Development Practices

### Hot Reload Workflow
- Save files to trigger hot reload
- Use `r` in terminal for manual hot reload  
- Use `R` for hot restart (full app restart)

### Testing
- For every new feature, suggest a corresponding widget test and unit test for the business logic.
- Use `WidgetTester` for widget tests
- `pumpWidget()` to build widgets
- `pump()` to trigger frames after interactions
- `find.byIcon()`, `find.text()` for element selection

### Common Tasks
- **Add new screens**: Create StatelessWidget/StatefulWidget in `lib/`
- **Add navigation**: Use `Navigator.push()` with MaterialPageRoute
- **Add assets**: Declare in `pubspec.yaml` assets section
- **Platform features**: Add platform channels or use packages

## Debugging & Performance
- Use Flutter Inspector in VS Code/Android Studio
- `flutter logs` for device logs
- Add `debugPrint()` statements for debugging (avoid `print()`)
- Performance overlay: `flutter run --profile`