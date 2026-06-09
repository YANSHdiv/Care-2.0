import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../../providers/location_provider.dart';
import '../../../providers/nearby_care_provider.dart';
import 'package:url_launcher/url_launcher.dart';
class NearbyCareScreen extends ConsumerStatefulWidget {
  const NearbyCareScreen({super.key});

  @override
  ConsumerState<NearbyCareScreen> createState() => _NearbyCareScreenState();
}

class _NearbyCareScreenState extends ConsumerState<NearbyCareScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);
    final nearbyState = ref.watch(nearbyCareProvider);

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShaderMask(
                      shaderCallback: (b) => Care2Theme.primaryGradient.createShader(b),
                      child: const Text(
                        'Nearby Care',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Care2Theme.textSecondary),
                      onPressed: () => ref.read(locationProvider.notifier).initLocation(),
                    )
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Specialists filtered by your risk profile.',
                  style: TextStyle(color: Care2Theme.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 16),

                // Map placeholder with REAL location
                _buildMapSection(locationState),
                const SizedBox(height: 16),

                // Filter chips
                Row(
                  children: [
                    _buildFilterChip('All'),
                    const SizedBox(width: 8),
                    _buildFilterChip('hospital'),
                    const SizedBox(width: 8),
                    _buildFilterChip('clinic'),
                  ],
                ),
                const SizedBox(height: 16),

                // Facility list
                if (nearbyState.isLoading)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(color: Care2Theme.primary),
                  ))
                else if (nearbyState.errorMessage != null)
                  Center(child: Text("Error: ${nearbyState.errorMessage}", style: const TextStyle(color: Colors.red)))
                else if (nearbyState.facilities.isEmpty)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Text("No facilities found nearby.", style: TextStyle(color: Colors.white70)),
                  ))
                else
                  ...nearbyState.facilities
                      .where((f) => _selectedFilter == 'All' || f['type'] == _selectedFilter)
                      .map((f) => _buildFacilityCard(f)),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapSection(LocationState location) {
    final city = location.details?.city ?? "Detecting...";
    
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [Color(0xFF0F3460), Color(0xFF1A4080)]),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Simulated Grid
          ...List.generate(5, (i) => Positioned(
            top: 36.0 * i, left: 0, right: 0,
            child: Container(height: 1, color: Colors.white.withValues(alpha: 0.04)),
          )),
          // Pins (Static visualization for now)
          const Positioned(top: 60, left: 80, child: _MapPin(color: Care2Theme.riskRed, label: 'Nearby')),
          const Positioned(top: 90, right: 60, child: _MapPin(color: Care2Theme.secondary, label: 'Medical')),
          
          // Current location pulse
          Center(
            child: Container(
              width: 16, height: 16,
              decoration: BoxDecoration(
                color: Care2Theme.accent, shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [BoxShadow(color: Care2Theme.accent.withValues(alpha: 0.5), blurRadius: 12)],
              ),
            ),
          ),
          
          // Label
          Positioned(
            bottom: 8, right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, size: 12, color: Care2Theme.accent),
                  const SizedBox(width: 4),
                  Text(city, style: const TextStyle(fontSize: 11, color: Care2Theme.textSecondary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final selected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Care2Theme.primary.withValues(alpha: 0.15) : Care2Theme.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? Care2Theme.primary.withValues(alpha: 0.5) : Colors.transparent),
        ),
        child: Text(
          label[0].toUpperCase() + label.substring(1),
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Care2Theme.primary : Care2Theme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildFacilityCard(Map<String, dynamic> facility) {
    final relevance = (facility['relevance_score'] as num).toDouble();
    final distance = (facility['distance_km'] as num).toDouble();
    final type = facility['type'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: Care2Theme.glassDecoration(opacity: 0.06, borderRadius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: Care2Theme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  type == 'hospital' ? Icons.local_hospital : Icons.medical_services,
                  color: Care2Theme.primary, size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(facility['name'] ?? 'Facility', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 3),
                        Text('${facility['rating']}', style: const TextStyle(color: Care2Theme.textSecondary, fontSize: 12)),
                        const SizedBox(width: 10),
                        const Icon(Icons.location_on, color: Care2Theme.textTertiary, size: 14),
                        const SizedBox(width: 3),
                        Text('${distance.toStringAsFixed(1)} km', style: const TextStyle(color: Care2Theme.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: relevance > 0.6 ? Care2Theme.riskGreen.withValues(alpha: 0.15) : Care2Theme.riskAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${(relevance * 100).toInt()}% match',
                  style: TextStyle(
                    color: relevance > 0.6 ? Care2Theme.riskGreen : Care2Theme.riskAmber,
                    fontSize: 10, fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(facility['address'] ?? '', style: const TextStyle(color: Care2Theme.textTertiary, fontSize: 12)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final phone = facility['phone'] ?? '18001234567';
                    final url = Uri.parse('tel:$phone');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
                  },
                  icon: const Icon(Icons.phone, size: 16),
                  label: const Text('Call', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8), side: const BorderSide(color: Care2Theme.primary)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final query = Uri.encodeComponent('${facility['name']} ${facility['address'] ?? ''}');
                    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.directions, size: 16),
                  label: const Text('Navigate', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  final Color color;
  final String label;
  const _MapPin({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(4)),
          child: Text(label, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 2),
        Icon(Icons.location_on, color: color, size: 20),
      ],
    );
  }
}
