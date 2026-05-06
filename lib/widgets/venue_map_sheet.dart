import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:footheroes/theme/app_theme.dart';
import '../features/find_nearby/domain/entities/venue.dart';

class VenueMapSheet extends StatelessWidget {
  final Venue venue;

  const VenueMapSheet({super.key, required this.venue});

  @override
  Widget build(BuildContext context) {
    final location = LatLng(venue.latitude, venue.longitude);

    return Container(
      height: 300,
      decoration: const BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppTheme.mutedParchment,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(venue.name, style: AppTheme.bebasDisplay.copyWith(fontSize: 20)),
          if (venue.address != null)
            Text(venue.address!, style: AppTheme.labelSmall),
          const SizedBox(height: 16),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: location,
                  initialZoom: 15,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.footheroes.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: location,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.sparkBlue,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.sparkBlue.withValues(alpha: 0.4),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.sports_soccer, color: AppTheme.parchment, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
