import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/language_provider.dart';
import '../widgets/loading_indicator.dart';

class DeliveryTrackingScreen extends StatefulWidget {
  final String orderId;

  const DeliveryTrackingScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<DeliveryTrackingScreen> createState() => _DeliveryTrackingScreenState();
}

class _DeliveryTrackingScreenState extends State<DeliveryTrackingScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _driverLocation;
  LatLng? _destinationLocation;
  String _estimatedTime = '';
  Timer? _locationUpdateTimer;
  
  @override
  void initState() {
    super.initState();
    _loadDeliveryDetails();
  }
  
  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }
  
  Future<void> _loadDeliveryDetails() async {
    setState(() => _isLoading = true);
    
    try {
      final supabase = Supabase.instance.client;
      
      // Get order details including delivery address
      final orderResponse = await supabase
          .from('orders')
          .select('''
            id,
            user_id,
            delivery_address,
            status,
            created_at
          ''')
          .eq('id', widget.orderId)
          .single();
      
      // Get delivery tracking details
      final trackingResponse = await supabase
          .from('delivery_tracking')
          .select('''
            id,
            order_id,
            driver_id,
            driver_location,
            estimated_arrival_time,
            status
          ''')
          .eq('order_id', widget.orderId)
          .single();
      
      // Parse driver location
      final driverLocationData = trackingResponse['driver_location'];
      if (driverLocationData != null) {
        _driverLocation = LatLng(
          driverLocationData['latitude'],
          driverLocationData['longitude'],
        );
      }
      
      // Parse delivery address to get destination coordinates
      final deliveryAddress = orderResponse['delivery_address'];
      if (deliveryAddress != null) {
        // In a real app, you would use Geocoding API to convert address to coordinates
        // For demo purposes, we'll use a fixed location
        _destinationLocation = const LatLng(28.6139, 77.2090); // Delhi coordinates
        
        // Add markers
        _updateMarkers();
        
        // Draw route
        _drawRoute();
        
        // Set estimated time
        final estimatedTime = trackingResponse['estimated_arrival_time'];
        if (estimatedTime != null) {
          final arrivalTime = DateTime.parse(estimatedTime);
          final now = DateTime.now();
          final difference = arrivalTime.difference(now);
          
          if (difference.inMinutes > 0) {
            _estimatedTime = '${difference.inMinutes} minutes';
          } else {
            _estimatedTime = 'Arriving soon';
          }
        }
      }
      
      // Start periodic location updates
      _startLocationUpdates();
      
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading delivery details: $e');
      setState(() {
        _errorMessage = 'Error loading delivery details: $e';
        _isLoading = false;
      });
    }
  }
  
  void _startLocationUpdates() {
    // In a real app, you would use WebSocket or polling to get real-time updates
    // For demo purposes, we'll simulate updates with a timer
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _updateDriverLocation();
    });
  }
  
  Future<void> _updateDriverLocation() async {
    try {
      final supabase = Supabase.instance.client;
      
      final trackingResponse = await supabase
          .from('delivery_tracking')
          .select('driver_location')
          .eq('order_id', widget.orderId)
          .single();
          
      final driverLocationData = trackingResponse['driver_location'];
      if (driverLocationData != null) {
        setState(() {
          _driverLocation = LatLng(
            driverLocationData['latitude'],
            driverLocationData['longitude'],
          );
          
          // Update markers and route
          _updateMarkers();
          _drawRoute();
        });
      }
    } catch (e) {
      debugPrint('Error updating driver location: $e');
    }
  }
  
  void _updateMarkers() {
    if (_driverLocation == null || _destinationLocation == null) return;
    
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('driver'),
          position: _driverLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Delivery Driver'),
        ),
        Marker(
          markerId: const MarkerId('destination'),
          position: _destinationLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Delivery Address'),
        ),
      };
    });
  }
  
  void _drawRoute() {
    if (_driverLocation == null || _destinationLocation == null) return;
    
    // In a real app, you would use Google Directions API to get the actual route
    // For demo purposes, we'll draw a straight line
    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: [_driverLocation!, _destinationLocation!],
          color: Colors.blue,
          width: 5,
        ),
      };
    });
    
    // Fit bounds to show both markers
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(
            _driverLocation!.latitude < _destinationLocation!.latitude
                ? _driverLocation!.latitude
                : _destinationLocation!.latitude,
            _driverLocation!.longitude < _destinationLocation!.longitude
                ? _driverLocation!.longitude
                : _destinationLocation!.longitude,
          ),
          northeast: LatLng(
            _driverLocation!.latitude > _destinationLocation!.latitude
                ? _driverLocation!.latitude
                : _destinationLocation!.latitude,
            _driverLocation!.longitude > _destinationLocation!.longitude
                ? _driverLocation!.longitude
                : _destinationLocation!.longitude,
          ),
        ),
        100,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.getTranslatedText('track_delivery')),
      ),
      body: _isLoading
          ? const SwapLoadingIndicator(size: 80)
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(languageProvider.getTranslatedText('go_back')),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Map
                    Expanded(
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _driverLocation ?? const LatLng(28.6139, 77.2090),
                          zoom: 14,
                        ),
                        markers: _markers,
                        polylines: _polylines,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        zoomControlsEnabled: true,
                        mapToolbarEnabled: false,
                        onMapCreated: (controller) {
                          _mapController = controller;
                        },
                      ),
                    ),
                    
                    // Delivery Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            languageProvider.getTranslatedText('delivery_status'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${languageProvider.getTranslatedText('estimated_arrival')}: $_estimatedTime',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              // Refresh tracking data
                              _loadDeliveryDetails();
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: Text(languageProvider.getTranslatedText('refresh')),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
} 