import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/activity_model.dart';

class LocalStorageService {
  static const String _key = 'recent_activities';

  // 1. Save an activity locally (Offline Mode) - Maintains Recent 5
  Future<void> saveActivityLocally(ActivityModel activity) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Fetch existing list
      List<ActivityModel> activities = await getLocalActivities();

      // Add new activity to the start of the list (Top)
      activities.insert(0, activity);

      // Rule: Keep only the recent 5 activities
      if (activities.length > 5) {
        activities = activities.sublist(0, 5);
      }

      // Convert list to JSON String and save
      String encodedData = jsonEncode(
        activities.map((e) => e.toJson()).toList(),
      );

      await prefs.setString(_key, encodedData);
      print("💾 Saved locally! Total offline items: ${activities.length}");

    } catch (e) {
      print("❌ Error saving to local storage: $e");
    }
  }

  // 2. Retrieve the list of offline activities
  Future<List<ActivityModel>> getLocalActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? jsonString = prefs.getString(_key);

      if (jsonString != null) {
        // Decode JSON string back to List<ActivityModel>
        List<dynamic> jsonList = jsonDecode(jsonString);
        return jsonList.map((json) => ActivityModel.fromJson(json)).toList();
      }
    } catch (e) {
      print("❌ Error reading local storage: $e");
    }
    return []; // Return empty list if nothing is saved or error occurs
  }

  // 3. Remove a specific activity (Useful after successful Sync)
  Future<void> removeActivity(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<ActivityModel> activities = await getLocalActivities();

      // Remove the item with the matching ID
      activities.removeWhere((item) => item.id == id);

      // Save the updated list back
      String encodedData = jsonEncode(
        activities.map((e) => e.toJson()).toList(),
      );
      await prefs.setString(_key, encodedData);
      print("🗑️ Activity removed from local storage.");

    } catch (e) {
      print("❌ Error removing from local storage: $e");
    }
  }

  // 4. Clear all storage (For testing or resetting)
  Future<void> clearStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    print("🧹 Local storage cleared.");
  }
}