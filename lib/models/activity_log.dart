class ActivityLog {
  final String id;
  final double latitude;
  final double longitude;
  final String imagePath;
  final DateTime timestamp;

  ActivityLog({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.imagePath,
    required this.timestamp,
  });
}