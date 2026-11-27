// Points sqflite at the FFI implementation on Windows and Linux, which the
// sqflite plugin does not support. Android, iOS and macOS keep the plugin.
// Web builds use desktop_database_setup_web.dart instead, see
// setUpDesktopDatabase.

import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void setUpDesktopDatabase() {
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}
