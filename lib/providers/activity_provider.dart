import 'package:flutter/material.dart';
import '../models/activity_log.dart';

class ActivityProvider with ChangeNotifier {
  // Yeh list saari activities save karegi
  final List<ActivityLog> _activities = [];

  List<ActivityLog> get activities => _activities;

  // Nayi activity add karne ka function
  void addActivity(ActivityLog activity) {
    _activities.add(activity);
    notifyListeners(); // UI ko bataye ga ke update ho jao
  }
}