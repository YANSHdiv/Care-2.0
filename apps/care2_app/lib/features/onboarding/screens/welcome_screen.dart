import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import 'dart:math' as math;

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();

    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => context.go('/login?mode=login'),
            child: const Text('Login', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500, fontSize: 16)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton(
              onPressed: () => context.go('/login?mode=register'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FFC2),
                foregroundColor: const Color(0xFF003300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              child: const Text('Sign Up', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D1117), Color(0xFF1A1A2E), Color(0xFF0F3460)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          
          // Decorative glowing orbs to mimic the nebula background
          Positioned(
            top: 200,
            left: MediaQuery.of(context).size.width * 0.2,
            child: _buildGlowOrb(const Color(0xFF00FFC2), 400),
          ),
          Positioned(
            bottom: 100,
            right: MediaQuery.of(context).size.width * 0.1,
            child: _buildGlowOrb(const Color(0xFF02A2E2), 300),
          ),

          // Main Content Layer
          SafeArea(
            child: AnimatedBuilder(
              animation: _fadeController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnim.value,
                  child: child,
                );
              },
              child: SizedBox(
                width: double.infinity,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 60),
                      // App name with heavy neon glow
                      Text(
                        'Care 2.0',
                        style: TextStyle(
                          fontSize: 84,
                          fontFamily: 'Georgia', // using serif-like system font to match design
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF00FFC2),
                          shadows: [
                            Shadow(color: const Color(0xFF00FFC2).withValues(alpha: 0.6), blurRadius: 40),
                            Shadow(color: const Color(0xFF00FFC2).withValues(alpha: 0.3), blurRadius: 80),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Preventive Health, Redefined.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white54,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 80),
                      
                      // Feature Pills layout
                      // On large screens, we map them out nicely floating. Since this responds to width,
                      // we'll use a Wrap that behaves somewhat organically or fixed layout.
                      Center(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 800;
                            if (isWide) {
                              return _buildScatteredLayout();
                            } else {
                              return _buildColumnLayout();
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowOrb(Color c, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.withValues(alpha: 0.05),
        boxShadow: [
          BoxShadow(
             color: c.withValues(alpha: 0.15),
             blurRadius: size / 2,
             spreadRadius: size / 4,
          )
        ]
      ),
    );
  }

  Widget _buildScatteredLayout() {
    return SizedBox(
      width: 1000,
      height: 400,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Left Top
          Positioned(
            left: 20,
            top: 20,
            child: _buildGlassPill(Icons.directions_run_rounded, 'Air Quality Aware Workouts'),
          ),
          // Right Top
          Positioned(
            right: 0,
            top: 0,
            child: _buildGlassPill(Icons.restaurant_outlined, 'AI Food Analysis'),
          ),
          // Little floating decorative icon boxes
          Positioned(
            left: 420,
            top: 130,
            child: Transform.scale(
              scale: 0.8,
              child: _buildSmallGlassBox(Icons.auto_graph),
            ),
          ),
          Positioned(
            left: 550,
            top: 60,
            child: Transform.scale(
              scale: 0.9,
              child: _buildSmallGlassBox(Icons.smart_toy_outlined),
            ),
          ),
          // Bottom Left
          Positioned(
            left: 140,
            bottom: 40,
            child: _buildGlassPill(Icons.analytics_outlined, '30-Day Health Predictions'),
          ),
          // Bottom Right
          Positioned(
            right: 180,
            bottom: 20,
            child: _buildGlassPill(Icons.add_box_outlined, 'Smart Care Finder'),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildGlassPill(Icons.directions_run_rounded, 'Air Quality Aware Workouts'),
          const SizedBox(height: 20),
          _buildGlassPill(Icons.restaurant_outlined, 'AI Food Analysis'),
          const SizedBox(height: 20),
          _buildGlassPill(Icons.analytics_outlined, '30-Day Health Predictions'),
          const SizedBox(height: 20),
          _buildGlassPill(Icons.add_box_outlined, 'Smart Care Finder'),
        ],
      ),
    );
  }

  Widget _buildSmallGlassBox(IconData icon) {
    return Container(
      width: 70, height: 70,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FFC2).withValues(alpha: 0.05),
            blurRadius: 20, spreadRadius: 5
          )
        ],
      ),
      child: Center(
        child: Icon(icon, color: const Color(0xFF00FFC2).withValues(alpha: 0.8), size: 36),
      ),
    );
  }

  Widget _buildGlassPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon Box
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Icon(icon, color: const Color(0xFF00FFC2), size: 30),
          ),
          const SizedBox(width: 24),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(width: 32),
          // Checkmark
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: const Color(0xFF00FFC2).withValues(alpha: 0.4), blurRadius: 10)
              ]
            ),
            child: const Icon(
              Icons.check_circle,
              color: Color(0xFF00FFC2),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}
