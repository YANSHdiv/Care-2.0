import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Use hash-based URLs (/#/home) for GitHub Pages compatibility
  usePathUrlStrategy();
  runApp(
    const ProviderScope(
      child: Care2App(),
    ),
  );
}
