import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:strata/src/installer/skills_installer.dart';

import '../../bin/install_skills.dart' as bin_main;

void main() {
  group('InstallSkillsOptions', () {
    test('parses default options with empty args', () {
      final options = InstallSkillsOptions.parse([]);
      expect(options.isHelp, isFalse);
      expect(options.installClaude, isFalse);
      expect(options.isGlobal, isFalse);
      expect(options.force, isFalse);
      expect(options.targetDir, isNull);
    });

    test('parses help flags -h and --help', () {
      expect(InstallSkillsOptions.parse(['-h']).isHelp, isTrue);
      expect(InstallSkillsOptions.parse(['--help']).isHelp, isTrue);
    });

    test('parses --claude flag', () {
      expect(InstallSkillsOptions.parse(['--claude']).installClaude, isTrue);
    });

    test('parses --global flag', () {
      expect(InstallSkillsOptions.parse(['--global']).isGlobal, isTrue);
    });

    test('parses force flags -f and --force', () {
      expect(InstallSkillsOptions.parse(['-f']).force, isTrue);
      expect(InstallSkillsOptions.parse(['--force']).force, isTrue);
    });

    test('parses --target-dir and --target options', () {
      expect(
        InstallSkillsOptions.parse(['--target-dir=/custom/path']).targetDir,
        '/custom/path',
      );
      expect(
        InstallSkillsOptions.parse(['--target=/other/path']).targetDir,
        '/other/path',
      );
    });
  });

  group('StrataSkillsManifest', () {
    test('contains all 5 expected skills', () {
      expect(StrataSkillsManifest.allSkills.keys, containsAll([
        'strata',
        'strata-bootstrap',
        'strata-auth',
        'strata-feature',
        'strata-pagination',
      ]));
      expect(StrataSkillsManifest.allSkills.length, 5);
    });

    test('each skill contains frontmatter name and description', () {
      for (final entry in StrataSkillsManifest.allSkills.entries) {
        expect(entry.value, contains('name: ${entry.key}'));
        expect(entry.value, contains('description:'));
      }
    });
  });

  group('SkillsInstaller', () {
    late Directory tempDir;
    const installer = SkillsInstaller();

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('strata_skills_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('prints help and exits 0 when isHelp is true', () {
      final out = StringBuffer();
      final exitCode = installer.install(
        const InstallSkillsOptions(isHelp: true),
        output: out,
      );

      expect(exitCode, 0);
      expect(out.toString(), contains('Strata Framework Skills Installer'));
      expect(out.toString(), contains('Usage: dart run strata:install_skills'));
    });

    test('installs skills to .opencode/skills by default', () {
      final out = StringBuffer();
      final exitCode = installer.install(
        const InstallSkillsOptions(),
        baseDir: tempDir,
        output: out,
      );

      expect(exitCode, 0);
      expect(out.toString(), contains('Successfully installed'));

      final opencodeDir = Directory('${tempDir.path}/.opencode/skills');
      expect(opencodeDir.existsSync(), isTrue);

      for (final skill in StrataSkillsManifest.allSkills.keys) {
        final skillFile = File('${opencodeDir.path}/$skill/SKILL.md');
        expect(skillFile.existsSync(), isTrue, reason: 'Skill $skill must exist');
        expect(skillFile.readAsStringSync(), isNotEmpty);
      }
    });

    test('skips existing skills when force is false', () {
      final skillDir = Directory('${tempDir.path}/.opencode/skills/strata');
      skillDir.createSync(recursive: true);
      final skillFile = File('${skillDir.path}/SKILL.md');
      skillFile.writeAsStringSync('CUSTOM_CONTENT');

      final out = StringBuffer();
      final exitCode = installer.install(
        const InstallSkillsOptions(force: false),
        baseDir: tempDir,
        output: out,
      );

      expect(exitCode, 0);
      expect(out.toString(), contains('Skipped strata (already exists'));
      expect(skillFile.readAsStringSync(), 'CUSTOM_CONTENT');
    });

    test('overwrites existing skills when force is true', () {
      final skillDir = Directory('${tempDir.path}/.opencode/skills/strata');
      skillDir.createSync(recursive: true);
      final skillFile = File('${skillDir.path}/SKILL.md');
      skillFile.writeAsStringSync('CUSTOM_CONTENT');

      final out = StringBuffer();
      final exitCode = installer.install(
        const InstallSkillsOptions(force: true),
        baseDir: tempDir,
        output: out,
      );

      expect(exitCode, 0);
      expect(out.toString(), contains('Installed strata'));
      expect(skillFile.readAsStringSync(), isNot('CUSTOM_CONTENT'));
      expect(skillFile.readAsStringSync(), contains('name: strata'));
    });

    test('installs to both .opencode/skills and .claude/skills when installClaude is true', () {
      final out = StringBuffer();
      final exitCode = installer.install(
        const InstallSkillsOptions(installClaude: true),
        baseDir: tempDir,
        output: out,
      );

      expect(exitCode, 0);

      final opencodeDir = Directory('${tempDir.path}/.opencode/skills');
      final claudeDir = Directory('${tempDir.path}/.claude/skills');

      expect(opencodeDir.existsSync(), isTrue);
      expect(claudeDir.existsSync(), isTrue);

      for (final skill in StrataSkillsManifest.allSkills.keys) {
        expect(File('${opencodeDir.path}/$skill/SKILL.md').existsSync(), isTrue);
        expect(File('${claudeDir.path}/$skill/SKILL.md').existsSync(), isTrue);
      }
    });

    test('installs to custom targetDir when provided', () {
      final customDir = Directory('${tempDir.path}/my_custom_skills');
      final out = StringBuffer();
      final exitCode = installer.install(
        InstallSkillsOptions(targetDir: customDir.path),
        output: out,
      );

      expect(exitCode, 0);
      expect(customDir.existsSync(), isTrue);
      expect(File('${customDir.path}/strata/SKILL.md').existsSync(), isTrue);
    });

    test('installs globally using environment when homeDir is not provided', () {
      final out = StringBuffer();
      final exitCode = installer.install(
        const InstallSkillsOptions(isGlobal: true),
        output: out,
      );

      // On Windows or Linux/macOS, USERPROFILE or HOME is set in test environment
      expect(exitCode, 0);
      expect(out.toString(), contains('Successfully installed'));
    });

    test('returns 1 with error message when isGlobal is true but home cannot be resolved', () {
      final out = StringBuffer();
      final err = StringBuffer();
      final exitCode = installer.install(
        const InstallSkillsOptions(isGlobal: true),
        homeDir: '',
        output: out,
        errorOutput: err,
      );

      expect(exitCode, 1);
      expect(err.toString(), contains('Could not resolve user home directory'));
    });

    test('uses stdout and stderr when output/errorOutput are omitted', () {
      final exitCode = installer.install(
        const InstallSkillsOptions(isHelp: true),
      );
      expect(exitCode, 0);
    });

    test('bin/install_skills.dart runs with --help and exits cleanly', () {
      expect(() => bin_main.main(['--help']), returnsNormally);
    });
  });
}
