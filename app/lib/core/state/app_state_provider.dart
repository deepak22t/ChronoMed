import 'package:flutter/widgets.dart';
import 'app_state.dart';

/// Makes [AppState] available to any widget in the tree without manual drilling.
/// Usage: `AppStateProvider.of(context).someGetter`
class AppStateProvider extends InheritedNotifier<AppState> {
  const AppStateProvider({
    super.key,
    required AppState state,
    required super.child,
  }) : super(notifier: state);

  /// Returns the nearest [AppState] from the widget tree.
  static AppState of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<AppStateProvider>();
    assert(provider != null,
        'AppStateProvider not found. Wrap your app with AppStateProvider.');
    return provider!.notifier!;
  }
}
