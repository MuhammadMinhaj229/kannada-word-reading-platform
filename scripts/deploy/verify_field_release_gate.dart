import 'dart:io';

import '../../lib/core/config/assessment_release_gate.dart';

void main() {
  final gate = AssessmentReleaseGate.current;
  if (gate.isOpen) {
    stdout.writeln('Signed field-release authorization verified.');
    return;
  }

  stderr.writeln(
    'Signed Android release blocked: the participant release gate is closed.',
  );
  for (final blocker in gate.blockers) {
    stderr.writeln(' - ' + blocker);
  }
  exitCode = 1;
}
