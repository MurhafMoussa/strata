import 'dart:io';
import 'package:strata/src/installer/skills_installer.dart';

void main(List<String> args) {
  final options = InstallSkillsOptions.parse(args);
  const installer = SkillsInstaller();
  final code = installer.install(options);
  if (code != 0) {
    exit(code);
  }
}
