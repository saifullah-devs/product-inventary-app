import 'package:shared_preferences/shared_preferences.dart';
import '../constants/data_source_type.dart';

class AppPreferences {
  final SharedPreferences _sharedPreferences;

  AppPreferences(this._sharedPreferences);

  static const String _kActiveSourceKey = 'active_data_source';

  Future<void> setActiveSource(DataSourceType type) async {
    await _sharedPreferences.setString(_kActiveSourceKey, type.name);
  }

  DataSourceType? getActiveSource() {
    final String? sourceName = _sharedPreferences.getString(_kActiveSourceKey);
    if (sourceName == null) return null;

    return DataSourceType.values.firstWhere(
      (e) => e.name == sourceName,
      orElse: () => DataSourceType.sqflite,
    );
  }

  bool hasSelectedSource() => _sharedPreferences.containsKey(_kActiveSourceKey);
}
