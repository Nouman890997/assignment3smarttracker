import 'package:flutter/material.dart';
import '../models/activity_model.dart'; // ✅ Importing the correct file

class ActivityProvider with ChangeNotifier {
  // ✅ Using ActivityModel instead of ActivityLog
  final List<ActivityModel> _activities = [];

  List<ActivityModel> get activities => _activities;

  void addActivity(ActivityModel activity) {
    _activities.add(activity);
    notifyListeners();
  }

  // Optional: Function to clear list or set from API
  void setActivities(List<ActivityModel> list) {
    _activities.clear();
    _activities.addAll(list);
    notifyListeners();
  }
}