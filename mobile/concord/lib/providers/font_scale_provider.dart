import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'concord.fontScale';

/// The four text-size steps, sharing the web app's exact multipliers
/// (`src/styles/tokens.css`, `--font-scale`) so the *relative* jump between
/// steps feels the same on both platforms even though the two base type ramps
/// differ (mobile's body text is 15px, web's default step is a 14px
/// equivalent).
///
/// [previewPx] is what this step actually produces for mobile's body text
/// (`bodyLarge`, 15px at scale 1) - shown in the picker so "Large (17px)" is an
/// honest label here rather than a copy of web's "Large (16px)".
enum FontScaleOption {
  small(0.9286, 14),
  standard(1.0, 15),
  large(1.1429, 17),
  extraLarge(1.2857, 19);

  const FontScaleOption(this.scale, this.previewPx);

  final double scale;
  final int previewPx;

  /// Nearest option to an arbitrary stored scale. Used so a value written by a
  /// future build (or a hand-edited preference) still maps onto a selectable
  /// step instead of leaving the picker with nothing checked.
  static FontScaleOption nearest(double scale) {
    var best = FontScaleOption.standard;
    for (final option in FontScaleOption.values) {
      if ((option.scale - scale).abs() < (best.scale - scale).abs()) best = option;
    }
    return best;
  }
}

/// Persists the user's text-size preference as a plain multiplier. Applied by
/// `main.dart`, which feeds it to `ConcordTheme.dark()/.light()`; see the
/// `fontScale` doc comment there for why only type - never spacing, icons or
/// button sizes - scales with it.
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

/// The currently selected step, for UI that needs to show a checkmark.
final fontScaleOptionProvider = Provider<FontScaleOption>((ref) {
  return FontScaleOption.nearest(ref.watch(fontScaleControllerProvider));
});
