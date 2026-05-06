import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:footheroes/theme/app_theme.dart';

class HomeLocationSetupScreen extends ConsumerStatefulWidget {
  final VoidCallback onLocationSet;

  const HomeLocationSetupScreen({
    super.key,
    required this.onLocationSet,
  });

  @override
  ConsumerState<HomeLocationSetupScreen> createState() =>
      _HomeLocationSetupScreenState();
}

class _HomeLocationSetupScreenState extends ConsumerState<HomeLocationSetupScreen> {
  bool _isLoading = false;
  LatLng? _detectedLocation;

  @override
  void initState() {
    super.initState();
    _detectLocation();
  }

  Future<void> _detectLocation() async {
    setState(() => _isLoading = true);
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _detectedLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (_) {
      // Location detection failed
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.voidBg,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text('Set Your Home Location', style: AppTheme.bebasDisplay.copyWith(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              'This helps us find matches near you',
              style: AppTheme.dmSans.copyWith(fontSize: 14, color: AppTheme.gold),
            ),
            const SizedBox(height: 40),
            if (_isLoading)
              const CircularProgressIndicator(color: AppTheme.sparkBlue)
            else if (_detectedLocation != null) ...[
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.sparkBlue.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on, color: AppTheme.sparkBlue, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                'Location Detected',
                style: AppTheme.bodyBold,
              ),
              const SizedBox(height: 8),
              Text(
                '${_detectedLocation!.latitude.toStringAsFixed(4)}, ${_detectedLocation!.longitude.toStringAsFixed(4)}',
                style: AppTheme.labelSmall,
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: widget.onLocationSet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: AppTheme.heroCtaGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'USE THIS LOCATION',
                    style: AppTheme.dmSans.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.parchment,
                    ),
                  ),
                ),
              ),
            ] else ...[
              const Icon(Icons.error_outline, color: AppTheme.feedbackError, size: 40),
              const SizedBox(height: 16),
              Text('Could not detect location', style: AppTheme.bodyBold),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _detectLocation,
                child: Text('TRY AGAIN', style: AppTheme.labelSmall.copyWith(color: AppTheme.sparkBlue)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
