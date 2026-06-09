import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Biometrics
  double _age = 28;
  double _height = 170;
  double _weight = 70;
  String _bloodGroup = 'B+';

  // Genetic risks
  final Map<String, List<String>> _geneticRisks = {
    'Father': [],
    'Mother': [],
    'Paternal Grandfather': [],
    'Paternal Grandmother': [],
    'Maternal Grandfather': [],
    'Maternal Grandmother': [],
  };
  String _selectedRelative = 'Father';

  // Clinical history
  final List<String> _selectedConditions = [];

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
          child: Column(
            children: [
              // Progress bar
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: _currentPage > 0
                          ? () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                              );
                            }
                          : () => context.go('/'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        children: List.generate(3, (i) {
                          return Expanded(
                            child: Container(
                              height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                color: i <= _currentPage
                                    ? Care2Theme.primary
                                    : Care2Theme.surfaceVariant,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${_currentPage + 1}/3',
                      style: TextStyle(
                        color: Care2Theme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Pages
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: [
                    _buildBiometricsPage(),
                    _buildGeneticPage(),
                    _buildClinicalPage(),
                  ],
                ),
              ),

              // Next button
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _onNext,
                    child: Text(
                      _currentPage < 2 ? 'Continue' : 'Complete Setup',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onNext() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      // Complete onboarding
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Care2Theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Care2Theme.riskGreen.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.check, color: Care2Theme.riskGreen, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Profile Created!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _summaryRow('Age', '${_age.toInt()} years'),
            _summaryRow('Height', '${_height.toInt()} cm'),
            _summaryRow('Weight', '${_weight.toInt()} kg'),
            _summaryRow(
                'BMI',
                (_weight / ((_height / 100) * (_height / 100)))
                    .toStringAsFixed(1)),
            _summaryRow('Blood Group', _bloodGroup),
            if (_selectedConditions.isNotEmpty)
              _summaryRow('Conditions', _selectedConditions.join(', ')),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/home');
            },
            child: const Text('Go to Dashboard'),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Care2Theme.textSecondary)),
          Text(value,
              style: const TextStyle(
                  color: Care2Theme.textPrimary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ─── Step 1: Biometrics ───

  Widget _buildBiometricsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          ShaderMask(
            shaderCallback: (bounds) =>
                Care2Theme.primaryGradient.createShader(bounds),
            child: const Text(
              'Your Biometrics',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Help us understand your body metrics for personalized recommendations.',
            style: TextStyle(color: Care2Theme.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 32),

          // Age slider
          _buildSliderCard(
            icon: Icons.cake_outlined,
            label: 'Age',
            value: _age,
            min: 1,
            max: 100,
            suffix: 'years',
            onChanged: (v) => setState(() => _age = v),
          ),
          const SizedBox(height: 16),

          // Height slider
          _buildSliderCard(
            icon: Icons.height,
            label: 'Height',
            value: _height,
            min: 100,
            max: 250,
            suffix: 'cm',
            onChanged: (v) => setState(() => _height = v),
          ),
          const SizedBox(height: 16),

          // Weight slider
          _buildSliderCard(
            icon: Icons.monitor_weight_outlined,
            label: 'Weight',
            value: _weight,
            min: 20,
            max: 200,
            suffix: 'kg',
            onChanged: (v) => setState(() => _weight = v),
          ),
          const SizedBox(height: 16),

          // Blood group
          Container(
            padding: const EdgeInsets.all(20),
            decoration:
                Care2Theme.glassDecoration(opacity: 0.06, borderRadius: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bloodtype,
                        color: Care2Theme.riskRed, size: 22),
                    const SizedBox(width: 10),
                    const Text('Blood Group',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppConstants.bloodGroups.map((bg) {
                    final selected = bg == _bloodGroup;
                    return ChoiceChip(
                      label: Text(bg),
                      selected: selected,
                      onSelected: (_) => setState(() => _bloodGroup = bg),
                      selectedColor: Care2Theme.primary.withValues(alpha: 0.25),
                      checkmarkColor: Care2Theme.primary,
                      labelStyle: TextStyle(
                        color: selected
                            ? Care2Theme.primary
                            : Care2Theme.textSecondary,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w400,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // BMI display
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: Care2Theme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.speed, color: Color(0xFF003300), size: 32),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your BMI',
                        style: TextStyle(
                            color: Color(0xFF003300),
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    Text(
                      (_weight / ((_height / 100) * (_height / 100)))
                          .toStringAsFixed(1),
                      style: const TextStyle(
                          color: Color(0xFF003300),
                          fontSize: 32,
                          fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF003300).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getBmiCategory(),
                    style: const TextStyle(
                        color: Color(0xFF003300),
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _getBmiCategory() {
    final bmi = _weight / ((_height / 100) * (_height / 100));
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Widget _buildSliderCard({
    required IconData icon,
    required String label,
    required double value,
    required double min,
    required double max,
    required String suffix,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: Care2Theme.glassDecoration(opacity: 0.06, borderRadius: 20),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: Care2Theme.primary, size: 22),
              const SizedBox(width: 10),
              Text(label,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Care2Theme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${value.toInt()} $suffix',
                  style: const TextStyle(
                    color: Care2Theme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min).toInt(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // ─── Step 2: Genetic Risk Mapping ───

  Widget _buildGeneticPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          ShaderMask(
            shaderCallback: (bounds) =>
                Care2Theme.purpleGradient.createShader(bounds),
            child: const Text(
              'Genetic Risk Map',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Map hereditary diseases in your family to assess genetic risk factors.',
            style: TextStyle(color: Care2Theme.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 24),

          // Relative selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration:
                Care2Theme.glassDecoration(opacity: 0.06, borderRadius: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Family Member',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppConstants.relatives.map((rel) {
                    final selected = rel == _selectedRelative;
                    final hasRisks =
                        (_geneticRisks[rel]?.isNotEmpty ?? false);
                    return FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(rel),
                          if (hasRisks) ...[
                            const SizedBox(width: 4),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Care2Theme.riskAmber,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      selected: selected,
                      onSelected: (_) =>
                          setState(() => _selectedRelative = rel),
                      selectedColor: Care2Theme.secondary.withValues(alpha: 0.25),
                      checkmarkColor: Care2Theme.secondary,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Disease selection
          Container(
            padding: const EdgeInsets.all(16),
            decoration:
                Care2Theme.glassDecoration(opacity: 0.06, borderRadius: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hereditary Conditions — $_selectedRelative',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                ...AppConstants.hereditaryDiseases.map((disease) {
                  final isSelected =
                      _geneticRisks[_selectedRelative]?.contains(disease) ??
                          false;
                  return CheckboxListTile(
                    title: Text(disease, style: const TextStyle(fontSize: 14)),
                    value: isSelected,
                    dense: true,
                    activeColor: Care2Theme.secondary,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _geneticRisks[_selectedRelative]?.add(disease);
                        } else {
                          _geneticRisks[_selectedRelative]?.remove(disease);
                        }
                      });
                    },
                  );
                }),
              ],
            ),
          ),

          // Summary
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Care2Theme.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Care2Theme.secondary.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.account_tree,
                        color: Care2Theme.secondary, size: 20),
                    SizedBox(width: 8),
                    Text('Risk Summary',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Care2Theme.secondary)),
                  ],
                ),
                const SizedBox(height: 8),
                ..._geneticRisks.entries
                    .where((e) => e.value.isNotEmpty)
                    .map((e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '${e.key}: ${e.value.join(", ")}',
                            style: TextStyle(
                                color: Care2Theme.textSecondary, fontSize: 13),
                          ),
                        )),
                if (_geneticRisks.values.every((v) => v.isEmpty))
                  Text('No hereditary conditions recorded.',
                      style: TextStyle(
                          color: Care2Theme.textTertiary, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ─── Step 3: Clinical History ───

  Widget _buildClinicalPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          ShaderMask(
            shaderCallback: (bounds) =>
                Care2Theme.dangerGradient.createShader(bounds),
            child: const Text(
              'Clinical History',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select your existing medical conditions and upload reports.',
            style: TextStyle(color: Care2Theme.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 24),

          // Conditions
          Container(
            padding: const EdgeInsets.all(16),
            decoration:
                Care2Theme.glassDecoration(opacity: 0.06, borderRadius: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.medical_information,
                        color: Care2Theme.riskAmber, size: 22),
                    SizedBox(width: 10),
                    Text('Medical Conditions',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppConstants.medicalConditions.map((condition) {
                    final selected =
                        _selectedConditions.contains(condition);
                    return FilterChip(
                      label: Text(condition),
                      selected: selected,
                      selectedColor:
                          Care2Theme.riskAmber.withValues(alpha: 0.2),
                      checkmarkColor: Care2Theme.riskAmber,
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _selectedConditions.add(condition);
                          } else {
                            _selectedConditions.remove(condition);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Upload report
          Container(
            padding: const EdgeInsets.all(20),
            decoration:
                Care2Theme.glassDecoration(opacity: 0.06, borderRadius: 20),
            child: Column(
              children: [
                Icon(Icons.cloud_upload_outlined,
                    color: Care2Theme.accent, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Upload Medical Reports',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'PDF, JPG, or PNG files. Our OCR engine will extract conditions automatically.',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: Care2Theme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    // In production: use file_picker
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                            'OCR parsing simulated — conditions added to profile.'),
                        backgroundColor: Care2Theme.cardColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Choose File'),
                ),
              ],
            ),
          ),

          // Selected conditions summary
          if (_selectedConditions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Care2Theme.riskAmber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Care2Theme.riskAmber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber,
                      color: Care2Theme.riskAmber, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${_selectedConditions.length} condition(s) selected. This will personalize your food and exercise recommendations.',
                      style: TextStyle(
                          color: Care2Theme.textSecondary, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
