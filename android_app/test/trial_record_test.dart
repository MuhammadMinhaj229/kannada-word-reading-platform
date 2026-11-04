import 'package:flutter_test/flutter_test.dart';
import 'package:padalab_android/features/assessment/domain/models/trial_record.dart';

void main() {
  final shownAt = DateTime.utc(2026, 11, 4, 12, 30);

  TrialRecord fixture({
    String phase = 'test',
    String? response = 'word',
    bool? correct = true,
    int? reactionTimeMs = 742,
  }) {
    return TrialRecord(
      trialUuid: 'trial-001',
      sessionUuid: 'session-001',
      phase: phase,
      trialNumber: 1,
      itemId: 'W001',
      itemText: 'ಕಮಲ',
      itemType: 'word',
      shownAt: shownAt,
      answeredAt: response == null
          ? null
          : shownAt.add(
              Duration(milliseconds: reactionTimeMs ?? 0),
            ),
      response: response,
      correct: correct,
      reactionTimeMs: reactionTimeMs,
      coinsSoFar: 0,
      appVersion: '0.1.0',
      itemBankVersion: 'pending',
    );
  }

  test('serializes correctness and reaction time using export field names', () {
    final row = fixture().toDatabaseMap();

    expect(row['item_id'], 'W001');
    expect(row['item_text'], 'ಕಮಲ');
    expect(row['item_type'], 'word');
    expect(row['response'], 'word');
    expect(row['correct'], 1);
    expect(row['rt_ms'], 742);
    expect(row['shown_at'], shownAt.toIso8601String());
  });

  test('keeps missing responses distinguishable from incorrect answers', () {
    final row = fixture(
      response: 'none',
      correct: null,
      reactionTimeMs: null,
    ).toDatabaseMap();

    expect(row['response'], 'none');
    expect(row['correct'], isNull);
    expect(row['rt_ms'], isNull);
  });

  test('rejects invalid trial phases', () {
    expect(
      () => fixture(phase: 'scored').toDatabaseMap(),
      throwsArgumentError,
    );
  });

  test('rejects correctness when no answer exists', () {
    expect(
      () => fixture(response: null, correct: true).toDatabaseMap(),
      throwsArgumentError,
    );
  });
}
##[group]Run dart format --output=none --set-exit-if-changed lib test
[36;1mdart format --output=none --set-exit-if-changed lib test[0m
shell: /usr/bin/bash -e {0}
env:
  JAVA_HOME: /opt/hostedtoolcache/Java_Temurin-Hotspot_jdk/17.0.21-9/x64
  JAVA_HOME_17_X64: /opt/hostedtoolcache/Java_Temurin-Hotspot_jdk/17.0.21-9/x64
  FLUTTER_ROOT: /opt/hostedtoolcache/flutter/stable-3.47.9-x64/flutter
  PUB_CACHE: /home/runner/.pub-cache
##[endgroup]
Formatted 16 files (0 changed) in 0.04 seconds.
##[group]Run flutter analyze --fatal-infos
[36;1mflutter analyze --fatal-infos[0m
shell: /usr/bin/bash -e {0}
env:
  JAVA_HOME: /opt/hostedtoolcache/Java_Temurin-Hotspot_jdk/17.0.21-9/x64
  JAVA_HOME_17_X64: /opt/hostedtoolcache/Java_Temurin-Hotspot_jdk/17.0.21-9/x64
  FLUTTER_ROOT: /opt/hostedtoolcache/flutter/stable-3.47.9-x64/flutter
  PUB_CACHE: /home/runner/.pub-cache
##[endgroup]
Analyzing android_app...                                        

   info • Sort directive sections alphabetically. Try sorting the directives • lib/app/padalab_app.dart:4:1 • directives_ordering
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • test/session_allocator_test.dart:6:21 • prefer_const_constructors
  error • The name 'MyApp' isn't a class. Try correcting the name to match an existing class • test/widget_test.dart:16:35 • creation_with_non_type

3 issues found. (ran in 13.2s)
##[error]Process completed with exit code 1.
Post job cleanup.
##[start-action display=Cache pub dependencies;id=__ee90267b-1e87-4953-bd51-58393ef37978.cache-pub]
##[end-action id=__ee90267b-1e87-4953-bd51-58393ef37978.cache-pub;outcome=skipped;conclusion=skipped;duration_ms=0]
##[start-action display=Cache Flutter;id=__ee90267b-1e87-4953-bd51-58393ef37978.cache-flutter]
##[end-action id=__ee90267b-1e87-4953-bd51-58393ef37978.cache-flutter;outcome=skipped;conclusion=skipped;duration_ms=0]
Post job cleanup.
(node:2717) [DEP0040] DeprecationWarning: The `punycode` module is deprecated. Please use a userland alternative instead.
(Use `node --trace-deprecation ...` to show where the warning was created)
Post job cleanup.
[command]/usr/bin/git version
git version 2.56.0
Temporarily overriding HOME='/home/runner/work/_temp/06e6d3a0-ab78-4ab8-9859-63c6d57c13a9' before making global git config changes
Adding repository directory to the temporary git global config as a safe directory
[command]/usr/bin/git config --global --add safe.directory /home/runner/work/kannada-word-reading-platform/kannada-word-reading-platform
[command]/usr/bin/git config --local --name-only --get-regexp core\.sshCommand
[command]/usr/bin/git submodule foreach --recursive sh -c "git config --local --name-only --get-regexp 'core\.sshCommand' && git config --local --unset-all 'core.sshCommand' || :"
[command]/usr/bin/git config --local --name-only --get-regexp http\.https\:\/\/github\.com\/\.extraheader
http.https://github.com/.extraheader
[command]/usr/bin/git config --local --unset-all http.https://github.com/.extraheader
[command]/usr/bin/git submodule foreach --recursive sh -c "git config --local --name-only --get-regexp 'http\.https\:\/\/github\.com\/\.extraheader' && git config --local --unset-all 'http.https://github.com/.extraheader' || :"
[command]/usr/bin/git config --local --name-only --get-regexp ^includeIf\.gitdir:
[command]/usr/bin/git submodule foreach --recursive git config --local --show-origin --name-only --get-regexp remote.origin.url
Cleaning up orphan processes
##[warning]Node.js 20 is deprecated. The following actions target Node.js 20 but are being forced to run on Node.js 24: actions/checkout@v4, actions/setup-java@v4. For more information see: https://github.blog/changelog/2025-09-19-deprecation-of-node-20-on-github-actions-runners/
