import 'dart:async';
import 'dart:html' as html;

/// Requests a worker update and activates it only after the user presses
/// Refresh updates from the idle assessor workspace.
Future<bool> checkAndActivateWebUpdate() async {
  final serviceWorkers = html.window.navigator.serviceWorker;
  if (serviceWorkers == null) return false;

  final registration = await serviceWorkers.getRegistration('/');
  if (registration == null) return false;

  await registration.update();
  var waiting = registration.waiting;

  final installing = registration.installing;
  if (waiting == null && installing != null) {
    final completed = Completer<void>();
    void onStateChange(html.Event _) {
      final state = installing.state;
      if (state == 'installed' || state == 'redundant') {
        installing.removeEventListener('statechange', onStateChange);
        if (!completed.isCompleted) completed.complete();
      }
    }

    installing.addEventListener('statechange', onStateChange);
    try {
      await completed.future.timeout(const Duration(minutes: 2));
    } on TimeoutException {
      installing.removeEventListener('statechange', onStateChange);
      return false;
    }
    waiting = registration.waiting;
  }

  if (waiting == null) return false;
  waiting.postMessage(<String, String>{'type': 'SKIP_WAITING'});
  return true;
}
