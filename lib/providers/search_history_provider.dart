import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryProvider with ChangeNotifier {
  List<String> _searchHistory = [];
  static const String _key = 'search_history';
  static const int _maxItems = 10;

  List<String> get searchHistory => _searchHistory;

  SearchHistoryProvider() {
    _loadSearchHistory();
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_key) ?? [];
    _searchHistory = history;
    notifyListeners();
  }

  Future<void> addSearch(String query) async {
    if (query.trim().isEmpty) return;

    _searchHistory.remove(query);
    _searchHistory.insert(0, query);

    if (_searchHistory.length > _maxItems) {
      _searchHistory = _searchHistory.sublist(0, _maxItems);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _searchHistory);
    notifyListeners();
  }

  Future<void> removeSearch(String query) async {
    _searchHistory.remove(query);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _searchHistory);
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _searchHistory.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    notifyListeners();
  }
} 