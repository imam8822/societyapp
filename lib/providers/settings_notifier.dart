import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:society_app/core/api/api_services.dart';
import 'package:society_app/models/payment_models.dart';

class SettingsNotifier extends StateNotifier<AsyncValue<SocietySettings>> {
  SettingsNotifier() : super(const AsyncValue.loading()) {
    fetchSettings();
  }

  Future<void> fetchSettings() async {
    try {
      state = const AsyncValue.loading();
      final settings = await SettingsApi.getSettings();
      state = AsyncValue.data(settings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Synchronously get settings (returns null if not yet loaded)
  SocietySettings? get currentSettings => state.valueOrNull;
}

final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, AsyncValue<SocietySettings>>((ref) {
  return SettingsNotifier();
});
