import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'concord.fontScale';

enum FontScaleOption {
  small(0.9286, 14),
  standard(1.0, 15),
  large(1.1429, 17),
  extraLarge(1.2857, 19);

  const FontScaleOption(this.scale, this.previewPx);

  final double scale;
  final int previewPx;

  static FontScaleOption nearest(double scale) {
    var best = FontScaleOption.standard;
    for (final option in FontScaleOption.values) {
      if ((option.scale - scale).abs() < (best.scale - scale).abs()) best = option;
    }
    return best;
  }
}

class FontScaleController extends StateNotifier<double> {
  FontScaleController() : super(FontScaleOption.standard.scale) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getDouble(_prefsKey);
    if (saved != null) state = FontScaleOption.nearest(saved).scale;
  }

  Future<void> setOption(FontScaleOption option) async {
    state = option.scale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefsKey, option.scale);
  }
}

final fontScaleControllerProvider = StateNotifierProvider<FontScaleController, double>((ref) {
  return FontScaleController();
});

final fontScaleOptionProvider = Provider<FontScaleOption>((ref) {
  return FontScaleOption.nearest(ref.watch(fontScaleControllerProvider));
});
