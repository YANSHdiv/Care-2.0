import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme.dart';
import 'routes.dart';

/// Provider that creates the GoRouter from auth state.
final routerProvider = Provider<dynamic>((ref) {
  return buildRouter(ref);
});

class Care2App extends ConsumerWidget {
  const Care2App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Care 2.0',
      debugShowCheckedModeBanner: false,
      theme: Care2Theme.darkTheme,
      routerConfig: router,
    );
  }
}
