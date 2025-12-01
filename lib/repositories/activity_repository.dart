import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/activity_model.dart';
import '../services/local_storage_service.dart';

class ActivityRepository {
  // Use 127.0.0.1 for faster Windows connection
  final String baseUrl = 'http://127.0.0.1:3000/activities';

  final LocalStorageService _localStorage = LocalStorageService();

  Future<bool> uploadActivity(ActivityModel activity) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(baseUrl));
      request.fields['latitude'] = activity.latitude.toString();
      request.fields['longitude'] = activity.longitude.toString();
      request.fields['timestamp'] = activity.timestamp.toIso8601String();

      if (activity.imagePath.isNotEmpty) {
        var pic = await http.MultipartFile.fromPath('image', activity.imagePath);
        request.files.add(pic);
      }

      // ⚡ FAST MODE: Stop waiting after 2 seconds
      var streamedResponse = await request.send().timeout(const Duration(seconds: 2));

      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        await _localStorage.saveActivityLocally(activity);
        return false;
      }
    } catch (e) {
      // If no internet or server is off -> Save Locally instantly
      print("⚠️ Fast Offline Save");
      await _localStorage.saveActivityLocally(activity);
      return false;
    }
  }

  // ... keep fetchActivities and deleteActivity as they are ...
  // (Make sure to verify if fetchActivities needs a timeout too if it is slow)
  Future<List<ActivityModel>> fetchActivities() async {
    try {
      // Also add timeout here for fast loading of history
      final response = await http.get(Uri.parse(baseUrl)).timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => ActivityModel.fromJson(item)).toList();
      }
      // If server fails, return local data
      return await _localStorage.getLocalActivities();
    } catch (e) {
      // If no internet, return local data
      return await _localStorage.getLocalActivities();
    }
  }

  // ... deleteActivity ...
  Future<bool> deleteActivity(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/$id'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}