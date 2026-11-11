import 'dart:async';
import 'dart:html' as html;

/// Checks for a new Web worker only when the user presses Refresh app.
///
/// A waiting worker is activated only by this call. The page reload is issued
/// once after the worker reaches the activated state. First-install activation
/// claims pages only after all app-shell assets are precached; it never forces
/// a reload.
Future<bool> checkAndActivateWebUpdate() async {
  final serviceWorkers = html.window.navigator.serviceWorker;
  if (serviceWorkers == null) return false;
  final registration = await serviceWorkers.getRegistration('/');

  await registration.update();
  var waiting = registration.waiting;

  if (waiting == null) {
    final installing = registration.installing;
    if (installing == null) return false;
    final state = await _waitForState(
      installing,
      const <String>{'installed', 'activated', 'redundant'},
    );
    if (state != 'installed') return false;
    waiting = registration.waiting;
  }

  if (waiting == null) return false;

  final activation = _waitForState(
    waiting,
    const <String>{'activated', 'redundant'},
  );
  waiting.postMessage(<String, String>{'type': 'SKIP_WAITING'});

  final finalState = await activation;
  if (finalState != 'activated') return false;

  html.window.location.reload();
  return true;
}

Future<String> _waitForState(
  html.ServiceWorker worker,
  Set<String> terminalStates,
) async {
  final completer = Completer<String>();
  late void Function(html.Event) listener;

  listener = (html.Event _) {
    final state = worker.state;
    if (terminalStates.contains(state)) {
      worker.removeEventListener('statechange', listener);
      if (!completer.isCompleted) completer.complete(state);
    }
  };

  worker.addEventListener('statechange', listener);
  listener(html.Event('statechange'));

  try {
    return await completer.future.timeout(const Duration(minutes: 2));
  } on TimeoutException {
    worker.removeEventListener('statechange', listener);
    return 'timeout';
  }
}
