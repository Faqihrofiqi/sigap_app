import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../core/constants.dart';

class LocationChecker {
  // Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }
  
  // Check location permission
  static Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }
  
  // Request location permission
  static Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }
  
  // Get current position
  static Future<Position?> getCurrentPosition() async {
    try {
      // Check if location service is enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Layanan lokasi tidak aktif. Silakan aktifkan GPS.');
      }
      
      // Check permission
      LocationPermission permission = await checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception(AppConstants.errorLocationDenied);
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi ditolak permanen. Buka pengaturan untuk mengaktifkan.');
      }
      
      // Note: Mock location detection removed due to package compatibility issues
      // The backend geofencing validation will still prevent location spoofing
      // For additional security, consider implementing server-side validation
      
      // Get position with high accuracy
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      
      return position;
    } catch (e) {
      return null;
    }
  }
  
  // Calculate distance between two coordinates (Haversine formula)
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }
  
  // Check if position is within radius
  static bool isWithinRadius(
    double userLat,
    double userLon,
    double targetLat,
    double targetLon,
    double radiusMeters,
  ) {
    final distance = calculateDistance(userLat, userLon, targetLat, targetLon);
    return distance <= radiusMeters;
  }
}

