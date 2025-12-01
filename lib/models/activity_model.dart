class ActivityModel {
  final String? id; // Nullable because a new item doesn't have an ID from server yet
  final double latitude;
  final double longitude;
  final String imagePath;
  final DateTime timestamp;

  ActivityModel({
    this.id,
    required this.latitude,
    required this.longitude,
    required this.imagePath,
    required this.timestamp,
  });

  // 1. Convert Server Data (JSON) -> Object
  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id'].toString(),
      // Safely parse numbers (sometimes server sends string, sometimes number)
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      imagePath: json['image_path'] ?? json['image_url'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  // 2. Convert Object -> JSON (For Server & Local Storage)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'image_path': imagePath,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}