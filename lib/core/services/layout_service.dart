import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LayoutService extends ChangeNotifier {
  static const String _isGridViewKey = 'is_grid_view_pref';
  bool _isGridView = true;

  bool get isGridView => _isGridView;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isGridView = prefs.getBool(_isGridViewKey) ?? true;
    notifyListeners();
  }

  Future<void> toggleView() async {
    _isGridView = !_isGridView;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isGridViewKey, _isGridView);
  }
}
