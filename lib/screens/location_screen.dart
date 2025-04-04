import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/language_provider.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({Key? key}) : super(key: key);

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  bool _isLoading = false;
  Position? _currentPosition;
  String? _currentAddress;
  bool _locationEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _loadLocationSettings();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location services are disabled'),
          ),
        );
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are denied'),
            ),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permissions are permanently denied, we cannot request permissions.',
            ),
          ),
        );
      }
      return;
    }

    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() => _isLoading = true);
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _locationEnabled = true;
      });

      await _updateLocationInDatabase(position);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadLocationSettings() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await supabase
          .from('user_settings')
          .select('location_enabled')
          .eq('user_id', user.id)
          .single();

      setState(() {
        _locationEnabled = response['location_enabled'] ?? false;
      });
    } catch (e) {
      print('Error loading location settings: $e');
    }
  }

  Future<void> _updateLocationInDatabase(Position position) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase.from('user_locations').upsert({
        'user_id': user.id,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'updated_at': DateTime.now().toIso8601String(),
      });

      await supabase.from('user_settings').upsert({
        'user_id': user.id,
        'location_enabled': _locationEnabled,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating location: $e')),
        );
      }
    }
  }

  Future<void> _toggleLocationServices() async {
    if (!_locationEnabled) {
      await _checkLocationPermission();
    } else {
      setState(() {
        _locationEnabled = false;
        _currentPosition = null;
        _currentAddress = null;
      });

      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      try {
        await supabase.from('user_settings').upsert({
          'user_id': user.id,
          'location_enabled': false,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating settings: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.getTranslatedText('location')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: SwitchListTile(
                title: Text(
                  languageProvider.getTranslatedText('location_services'),
                ),
                subtitle: Text(
                  languageProvider.getTranslatedText('location_services_desc'),
                ),
                value: _locationEnabled,
                onChanged: (value) => _toggleLocationServices(),
              ),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_locationEnabled && _currentPosition != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        languageProvider.getTranslatedText('current_location'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Latitude: ${_currentPosition!.latitude}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Longitude: ${_currentPosition!.longitude}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      if (_currentAddress != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _currentAddress!,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _getCurrentLocation,
                          icon: const Icon(Icons.refresh),
                          label: Text(
                            languageProvider.getTranslatedText('refresh_location'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      languageProvider.getTranslatedText('location_info'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      languageProvider.getTranslatedText('location_info_desc'),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 