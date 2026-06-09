import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../../providers/auth_provider.dart';

class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});

  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _analysisResult;
  final ImagePicker _picker = ImagePicker();
  
  String _selectedMealType = 'Snack';
  final List<Map<String, dynamic>> _recentMeals = [
    {'name': 'Masala Dosa', 'cal': '380 kcal', 'type': 'Breakfast', 'color': Care2Theme.riskGreen, 'suitable': true},
    {'name': 'Dal Makhani + Naan', 'cal': '580 kcal', 'type': 'Lunch', 'color': Care2Theme.riskAmber, 'suitable': true},
    {'name': 'Samosa (2 pcs)', 'cal': '620 kcal', 'type': 'Snack', 'color': Care2Theme.riskRed, 'suitable': false},
  ];

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source, maxWidth: 800, maxHeight: 800);
      if (pickedFile == null) return;
      
      setState(() => _isLoading = true);
      
      final authState = ref.read(authProvider);
      final formData = FormData.fromMap({
        'uid': authState.uid ?? 'demo_user',
        'meal_type': _selectedMealType.toLowerCase(),
      });
      
      if (kIsWeb) {
         final bytes = await pickedFile.readAsBytes();
         formData.files.add(MapEntry('image', MultipartFile.fromBytes(bytes, filename: 'food.jpg')));
      } else {
         formData.files.add(MapEntry('image', await MultipartFile.fromFile(pickedFile.path, filename: 'food.jpg')));
      }
      
      final dio = Dio();
      final response = await dio.post('http://localhost:8000/api/v1/nutrition/analyze', data: formData);
      
      if (response.statusCode == 200) {
        setState(() {
          _analysisResult = response.data;
          _isLoading = false;
          _recentMeals.insert(0, {
             'name': _analysisResult!['food_name'],
             'cal': '${_analysisResult!['nutrition']['calories']} kcal',
             'type': _selectedMealType,
             'color': (_analysisResult!['is_suitable'] as bool) ? Care2Theme.riskGreen : Care2Theme.riskRed,
             'suitable': _analysisResult!['is_suitable'],
          });
        });
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification Failed: \$e')));
      }
      setState(() => _isLoading = false);
    }
  }

  void _showPickerModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Care2Theme.surfaceVariant,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Care2Theme.primary),
              title: const Text('Photo Library', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Care2Theme.primary),
              title: const Text('Camera', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D1117), Color(0xFF1A1A2E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (b) =>
                      Care2Theme.primaryGradient.createShader(b),
                  child: const Text(
                    'Nutrition Scanner',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Scan your meals for AI-powered nutritional analysis.',
                  style: TextStyle(
                      color: Care2Theme.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 24),

                // Camera module
                if (_analysisResult == null) ...[
                  // Camera placeholder
                  GestureDetector(
                    onTap: _isLoading ? null : _showPickerModal,
                    child: Container(
                      width: double.infinity,
                      height: 300,
                      decoration: BoxDecoration(
                        color: Care2Theme.surfaceVariant,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color:
                                Care2Theme.primary.withValues(alpha: 0.3),
                            width: 2),
                      ),
                      child: _isLoading 
                        ? const Center(child: CircularProgressIndicator(color: Care2Theme.primary))
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      Care2Theme.primary.withValues(alpha: 0.15),
                                ),
                                child: const Icon(Icons.camera_alt,
                                    color: Care2Theme.primary, size: 48),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Tap to Scan Food',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Take a photo of your meal for instant analysis',
                                style: TextStyle(
                                    color: Care2Theme.textTertiary, fontSize: 13),
                              ),
                            ],
                          ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Meal type selector
                  Row(
                    children: [
                      _buildMealTypeChip('Breakfast'),
                      const SizedBox(width: 8),
                      _buildMealTypeChip('Lunch'),
                      const SizedBox(width: 8),
                      _buildMealTypeChip('Dinner'),
                      const SizedBox(width: 8),
                      _buildMealTypeChip('Snack'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Recent meals
                  const Text('Recent Meals',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  ..._recentMeals.map((meal) => _buildRecentMeal(
                      meal['name'], meal['cal'], meal['type'], meal['color'], meal['suitable'])),
                ] else ...[
                  // Analysis result
                  _buildAnalysisResult(),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMealTypeChip(String label) {
    final selected = _selectedMealType == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMealType = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? Care2Theme.primary.withValues(alpha: 0.15)
                : Care2Theme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? Care2Theme.primary.withValues(alpha: 0.5)
                  : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Care2Theme.primary : Care2Theme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentMeal(
      String name, String cal, String type, Color statusColor, bool suitable) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: Care2Theme.glassDecoration(opacity: 0.06, borderRadius: 14),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Care2Theme.cardColorLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.restaurant,
                color: Care2Theme.textTertiary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text('$cal · $type',
                    style: TextStyle(
                        color: Care2Theme.textTertiary, fontSize: 12)),
              ],
            ),
          ),
          Icon(
            suitable ? Icons.check_circle : Icons.warning_amber,
            color: statusColor,
            size: 22,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResult() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button
        TextButton.icon(
          onPressed: () => setState(() => _analysisResult = null),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Scan Again'),
        ),
        const SizedBox(height: 8),

        // Food image placeholder
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: Care2Theme.cardGradient,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.restaurant_menu,
                    size: 56, color: Care2Theme.primary),
                const SizedBox(height: 12),
                Text(
                  _analysisResult!['food_name'] as String,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Care2Theme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${((_analysisResult!['confidence'] as double) * 100).toInt()}% confidence',
                    style: const TextStyle(
                        color: Care2Theme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Suitability banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: (_analysisResult!['is_suitable'] as bool)
                ? Care2Theme.riskGreen.withValues(alpha: 0.1)
                : Care2Theme.riskRed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: (_analysisResult!['is_suitable'] as bool)
                  ? Care2Theme.riskGreen.withValues(alpha: 0.4)
                  : Care2Theme.riskRed.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              Icon(
                (_analysisResult!['is_suitable'] as bool) ? Icons.check_circle : Icons.cancel,
                color: (_analysisResult!['is_suitable'] as bool)
                    ? Care2Theme.riskGreen
                    : Care2Theme.riskRed,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  (_analysisResult!['is_suitable'] as bool)
                      ? 'This meal is suitable for your condition.'
                      : '⚠️ Not recommended for your medical conditions!',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: (_analysisResult!['is_suitable'] as bool)
                        ? Care2Theme.riskGreen
                        : Care2Theme.riskRed,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Macros
        Container(
          padding: const EdgeInsets.all(20),
          decoration: Care2Theme.glassDecoration(opacity: 0.06, borderRadius: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_fire_department,
                      color: Care2Theme.riskRed, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    '${_analysisResult!['nutrition']['calories']} kcal',
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildMacro('Protein', '${_analysisResult!['nutrition']['protein_g']}g',
                      Care2Theme.accent),
                  _buildMacro('Carbs', '${_analysisResult!['nutrition']['carbs_g']}g',
                      Care2Theme.riskAmber),
                  _buildMacro('Fat', '${_analysisResult!['nutrition']['fat_g']}g',
                      Care2Theme.riskRed),
                  _buildMacro('Fiber', '${_analysisResult!['nutrition']['fiber_g']}g',
                      Care2Theme.riskGreen),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Spike factors
        if ((_analysisResult!['spike_factors'] as List).isNotEmpty) ...[
          const Text('⚡ Spike Factors',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...(_analysisResult!['spike_factors'] as List).map((spike) {
            final color = spike['severity'] == 'high'
                ? Care2Theme.riskRed
                : Care2Theme.riskAmber;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber, color: color, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${spike['nutrient']}: ${spike['value']} (threshold: ${spike['threshold']})',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, color: color),
                        ),
                        const SizedBox(height: 4),
                        Text(spike['warning'] as String,
                            style: TextStyle(
                                color: Care2Theme.textSecondary,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
        const SizedBox(height: 16),

        // Alternatives
        if ((_analysisResult!['alternative_suggestions'] as List).isNotEmpty) ...[
          const Text('💡 Healthier Alternatives',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...(_analysisResult!['alternative_suggestions'] as List).map((alt) {
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Care2Theme.riskGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Care2Theme.riskGreen.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.swap_horiz,
                      color: Care2Theme.riskGreen, size: 18),
                  const SizedBox(width: 10),
                  Text(alt as String,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 14)),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildMacro(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  color: Care2Theme.textTertiary, fontSize: 11)),
        ],
      ),
    );
  }
}
