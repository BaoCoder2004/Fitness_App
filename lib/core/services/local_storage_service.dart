import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  LocalStorageService({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  // Activities
  Future<void> saveActivityOffline(String userId, Map<String, dynamic> activityData) async {
    final prefs = await _preferences;
    final key = 'offline_activities_$userId';
    final activities = await getActivitiesOffline(userId);
    
    // Generate ID nếu chưa có
    if (activityData['id'] == null || (activityData['id'] as String).isEmpty) {
      activityData['id'] = 'offline_${DateTime.now().millisecondsSinceEpoch}';
    }
    
    final activityId = activityData['id'] as String;
    
    // Kiểm tra xem activity đã tồn tại chưa (update thay vì add duplicate)
    final existingIndex = activities.indexWhere((a) => a['id'] == activityId);
    if (existingIndex >= 0) {
      activities[existingIndex] = activityData;
    } else {
      activities.add(activityData);
    }
    
    await prefs.setString(key, jsonEncode(activities));
  }

  Future<List<Map<String, dynamic>>> getActivitiesOffline(String userId) async {
    final prefs = await _preferences;
    final key = 'offline_activities_$userId';
    final jsonString = prefs.getString(key);
    if (jsonString == null) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => Map<String, dynamic>.from(json as Map)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> removeActivityOffline(String userId, String activityId) async {
    final prefs = await _preferences;
    final key = 'offline_activities_$userId';
    final activities = await getActivitiesOffline(userId);
    activities.removeWhere((activity) => activity['id'] == activityId);
    await prefs.setString(key, jsonEncode(activities));
  }

  Future<void> clearActivitiesOffline(String userId) async {
    final prefs = await _preferences;
    final key = 'offline_activities_$userId';
    await prefs.remove(key);
  }

  // Goals
  Future<void> saveGoalOffline(String userId, Map<String, dynamic> goalData) async {
    final prefs = await _preferences;
    final key = 'offline_goals_$userId';
    final goals = await getGoalsOffline(userId);
    
    // Generate ID nếu chưa có
    if (goalData['id'] == null || (goalData['id'] as String).isEmpty) {
      goalData['id'] = 'offline_${DateTime.now().millisecondsSinceEpoch}';
    }
    
    final goalId = goalData['id'] as String;
    
    // Kiểm tra xem goal đã tồn tại chưa (update thay vì add duplicate)
    final existingIndex = goals.indexWhere((g) => g['id'] == goalId);
    if (existingIndex >= 0) {
      goals[existingIndex] = goalData;
    } else {
      goals.add(goalData);
    }
    
    await prefs.setString(key, jsonEncode(goals));
  }

  Future<List<Map<String, dynamic>>> getGoalsOffline(String userId) async {
    final prefs = await _preferences;
    final key = 'offline_goals_$userId';
    final jsonString = prefs.getString(key);
    if (jsonString == null) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => Map<String, dynamic>.from(json as Map)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> removeGoalOffline(String userId, String goalId) async {
    final prefs = await _preferences;
    final key = 'offline_goals_$userId';
    final goals = await getGoalsOffline(userId);
    goals.removeWhere((goal) => goal['id'] == goalId);
    await prefs.setString(key, jsonEncode(goals));
  }

  Future<void> clearGoalsOffline(String userId) async {
    final prefs = await _preferences;
    final key = 'offline_goals_$userId';
    await prefs.remove(key);
  }

  // GPS Routes
  Future<void> saveGpsRouteOffline(String userId, Map<String, dynamic> routeData) async {
    final prefs = await _preferences;
    final key = 'offline_gps_routes_$userId';
    final routes = await getGpsRoutesOffline(userId);
    
    // Generate ID nếu chưa có
    if (routeData['id'] == null || (routeData['id'] as String).isEmpty) {
      routeData['id'] = 'offline_${DateTime.now().millisecondsSinceEpoch}';
    }
    
    final routeId = routeData['id'] as String;
    
    // Kiểm tra xem route đã tồn tại chưa (update thay vì add duplicate)
    final existingIndex = routes.indexWhere((r) => r['id'] == routeId);
    if (existingIndex >= 0) {
      routes[existingIndex] = routeData;
    } else {
      routes.add(routeData);
    }
    
    await prefs.setString(key, jsonEncode(routes));
  }

  Future<List<Map<String, dynamic>>> getGpsRoutesOffline(String userId) async {
    final prefs = await _preferences;
    final key = 'offline_gps_routes_$userId';
    final jsonString = prefs.getString(key);
    if (jsonString == null) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => Map<String, dynamic>.from(json as Map)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> removeGpsRouteOffline(String userId, String routeId) async {
    final prefs = await _preferences;
    final key = 'offline_gps_routes_$userId';
    final routes = await getGpsRoutesOffline(userId);
    routes.removeWhere((route) => route['id'] == routeId);
    await prefs.setString(key, jsonEncode(routes));
  }

  Future<void> clearGpsRoutesOffline(String userId) async {
    final prefs = await _preferences;
    final key = 'offline_gps_routes_$userId';
    await prefs.remove(key);
  }

  // Clear all offline data for a user
  Future<void> clearAllOfflineData(String userId) async {
    await clearActivitiesOffline(userId);
    await clearGoalsOffline(userId);
    await clearGpsRoutesOffline(userId);
  }
}

