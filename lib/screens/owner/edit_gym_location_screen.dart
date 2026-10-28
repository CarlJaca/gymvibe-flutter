import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/gym_provider.dart';

class EditGymLocationScreen extends StatefulWidget {
  const EditGymLocationScreen({super.key});

  @override
  State<EditGymLocationScreen> createState() => _EditGymLocationScreenState();
}

class _EditGymLocationScreenState extends State<EditGymLocationScreen> {
  late MapController _mapController;
  LatLng? _currentPosition;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    
    // Initialize with gym's current coordinates, or fallback to default (e.g. Davao City)
    final gymProv = context.read<GymProvider>();
    final gym = gymProv.ownerGym;
    
    if (gym.latitude != 0.0 && gym.longitude != 0.0) {
      _currentPosition = LatLng(gym.latitude, gym.longitude);
    } else {
      _currentPosition = const LatLng(7.0702, 125.6125); // Default to Davao City center
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _onMapTapped(TapPosition tapPosition, LatLng point) {
    setState(() {
      _currentPosition = point;
    });
  }

  Future<void> _saveLocation() async {
    if (_currentPosition == null) return;
    
    setState(() => _isLoading = true);
    
    final gymProv = context.read<GymProvider>();
    final gym = gymProv.ownerGym;
    
    final updatedGym = gym.copyWith(
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
    );
    
    await gymProv.updateOwnerGym(updatedGym);
    
    setState(() => _isLoading = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gym location updated successfully!'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Gym Location', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppPadding.md),
            color: AppColors.surface,
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tap anywhere on the map to place your gym marker. This helps job seekers find you.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentPosition!,
                initialZoom: 15.0,
                onTap: _onMapTapped,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.gymvibe.app',
                ),
                if (_currentPosition != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _currentPosition!,
                        width: 40,
                        height: 40,
                        alignment: Alignment.topCenter,
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: AppColors.error,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppPadding.lg),
            decoration: const BoxDecoration(
              color: AppColors.surfaceElevated,
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))
              ]
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Save Location', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
