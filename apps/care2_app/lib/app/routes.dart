import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/onboarding/screens/welcome_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/dashboard/screens/home_screen.dart';
import '../features/environment/screens/environment_screen.dart';
import '../features/nutrition/screens/nutrition_screen.dart';
import '../features/dashboard/screens/prediction_screen.dart';
import '../features/nearby_care/screens/nearby_care_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../providers/auth_provider.dart';

/// Build the router, refreshing on auth state changes.
GoRouter buildRouter(Ref ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoading = auth.isLoading;
      final isLoggedIn = auth.isAuthenticated;
      final currentPath = state.uri.path;

      // While auth is still restoring, don't redirect
      if (isLoading) return null;

      // Public routes that don't require auth
      const publicRoutes = ['/', '/login', '/onboarding'];
      final isPublicRoute = publicRoutes.contains(currentPath);

      // If logged in and on a public route, go home or onboarding
      if (isLoggedIn && isPublicRoute) {
        if (currentPath == '/onboarding') return null; // let them finish onboarding
        return auth.isNewUser ? '/onboarding' : '/home';
      }

      // If not logged in and on a protected route, go to welcome
      if (!isLoggedIn && !isPublicRoute) return '/';

      return null; // No redirect needed
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) {
          final mode = state.uri.queryParameters['mode'];
          return LoginScreen(initialMode: mode);
        },
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/environment',
            builder: (context, state) => const EnvironmentScreen(),
          ),
          GoRoute(
            path: '/nutrition',
            builder: (context, state) => const NutritionScreen(),
          ),
          GoRoute(
            path: '/predictions',
            builder: (context, state) => const PredictionScreen(),
          ),
          GoRoute(
            path: '/nearby',
            builder: (context, state) => const NearbyCareScreen(),
          ),
        ],
      ),
    ],
  );
}

/// Main app shell with bottom navigation
class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/environment')) return 1;
    if (location.startsWith('/nutrition')) return 2;
    if (location.startsWith('/predictions')) return 3;
    if (location.startsWith('/nearby')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _currentIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        child: NavigationBar(
          selectedIndex: idx,
          backgroundColor: Colors.transparent,
          indicatorColor: const Color(0xFF00E5A0).withValues(alpha: 0.15),
          onDestinationSelected: (i) {
            const paths = ['/home', '/environment', '/nutrition', '/predictions', '/nearby'];
            context.go(paths[i]);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard, color: Color(0xFF00E5A0)),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.air_outlined),
              selectedIcon: Icon(Icons.air, color: Color(0xFF00E5A0)),
              label: 'Air',
            ),
            NavigationDestination(
              icon: Icon(Icons.restaurant_outlined),
              selectedIcon: Icon(Icons.restaurant, color: Color(0xFF00E5A0)),
              label: 'Food',
            ),
            NavigationDestination(
              icon: Icon(Icons.analytics_outlined),
              selectedIcon: Icon(Icons.analytics, color: Color(0xFF00E5A0)),
              label: 'Health',
            ),
            NavigationDestination(
              icon: Icon(Icons.local_hospital_outlined),
              selectedIcon: Icon(Icons.local_hospital, color: Color(0xFF00E5A0)),
              label: 'Care',
            ),
          ],
        ),
      ),
    );
  }
}
