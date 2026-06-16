import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_provider.g.dart';

@riverpod
class HideOtherNotifier extends _$HideOtherNotifier {
  static const _key = 'hide_other';

  @override
  bool build() {
    _loadHideOther();
    return true; // Default to hidden
  }

  Future<void> _loadHideOther() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? true;
  }

  Future<void> setHideOther(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}
