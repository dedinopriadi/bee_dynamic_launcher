import 'dart:io';

bool get _ansi =>
    stdout.supportsAnsiEscapes &&
    !Platform.environment.containsKey('NO_COLOR') &&
    Platform.environment['TERM'] != 'dumb';
bool get _tty => stdout.hasTerminal;

String _seq(String code, String s) => _ansi ? '\x1B[${code}m$s\x1B[0m' : s;

String bold(String s) => _seq('1', s);
String dim(String s) => _seq('2', s);
String green(String s) => _seq('32', s);
String yellow(String s) => _seq('33', s);
String red(String s) => _seq('31', s);
String cyan(String s) => _seq('36', s);

const _spinFrames = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];
int _spinI = 0;

void clearLine() {
  if (_tty) {
    stdout.write('\r\x1B[K');
  }
}

void banner() {
  stdout.writeln('');
  stdout.writeln(cyan('╔════════════════════════════════════════════╗'));
  stdout.writeln(
    '${cyan('║')}  🚀 ${bold('bee_dynamic_launcher')} ${dim('codegen')}       ${cyan('║')}',
  );
  stdout.writeln(cyan('╚════════════════════════════════════════════╝'));
  stdout.writeln('');
}

void section(String emoji, String title) {
  stdout.writeln('');
  stdout.writeln(bold(cyan('$emoji  $title')));
  stdout.writeln(dim('────────────────────────────────────────────'));
}

void stepOk(String text) {
  stdout.writeln('${green('  ✓')} $text');
}

void stepInfo(String text) {
  stdout.writeln('${cyan('  →')} $text');
}

void warnLine(String text) {
  stdout.writeln('${yellow('  ⚠')} $text');
}

void errLine(String text) {
  stderr.writeln('${red('  ✗')} $text');
}

void progressVariant(int index1, int total, String phase, String id) {
  if (!_tty) {
    stdout.writeln('[$index1/$total] $phase · $id');
    return;
  }
  final f = _spinFrames[_spinI++ % _spinFrames.length];
  final bracket = dim('[$index1/$total]');
  stdout.write('\r$f $bracket $phase · ${bold(id)}${dim(' …')}   ');
}

void progressDone(String summary) {
  clearLine();
  stepOk(summary);
}

void footerSuccess(String mode) {
  stdout.writeln('');
  stdout.writeln(green('  ✓ Done') + dim(' · $mode'));
  stdout.writeln('');
}

void footerFailure(String reason) {
  stdout.writeln('');
  errLine(reason);
  stdout.writeln('');
}

void printHelpPretty() {
  stdout.writeln('');
  stdout.writeln(bold(cyan('bee_dynamic_launcher — help')));
  stdout.writeln(dim('────────────────────────────────────────────'));
  stdout.writeln('');
  stdout.writeln(
      '  ${bold('(default)')}     Validate, Android+iOS codegen, resize icons');
  stdout.writeln('  ${cyan('--icons-only')}   Mipmaps + iOS PNGs only');
  stdout.writeln(
      '  ${cyan('--native-only')}   XML / plist / manifest (no LauncherVariants.kt)');
  stdout.writeln('  ${cyan('--skip-icons')}    Same as --native-only');
  stdout.writeln('  ${cyan('--scan')}         JSON variants vs icons/ic_*.png');
  stdout.writeln(
      '  ${cyan('--check-android-manifest')} Check AndroidManifest launcher config only (no writes)');
  stdout.writeln(
      '  ${cyan('--check-ios-pbxproj')} Check iOS project.pbxproj only (no writes)');
  stdout.writeln('  ${cyan('--strict')}       With --scan, fail on mismatch');
  stdout.writeln('  ${cyan('--wizard')}       Append variants interactively');
  stdout.writeln('  ${cyan('-h, --help')}      This screen');
  stdout.writeln('');
  stdout.writeln(
    dim('  Catalog: assets/bee_dynamic_launcher/catalog.json'),
  );
  stdout.writeln(
    dim('  Icons:   assets/bee_dynamic_launcher/icons/ic_<id>.png'),
  );
  stdout.writeln('');
  stdout.writeln(
      dim('  Colors respect NO_COLOR=1 · pipe/CI may show plain text'));
  stdout.writeln('');
}
