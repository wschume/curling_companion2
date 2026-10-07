// Run with dart --packages=.dart_tool/package_config.json from the repo root.
import 'dart:convert';
import 'dart:io';
import 'package:curling_companion/models/models.dart';

void main(List<String> args) {
  final data = jsonDecode(File(args.single).readAsStringSync()) as Map<String, dynamic>;
  final tournament = TournamentMapper.fromMap(data);
  final encoded = tournament.toMap();
  for (final key in data.keys) {
    if (encoded[key] != data[key]) {
      throw StateError('$key did not round-trip: ${data[key]} -> ${encoded[key]}');
    }
  }
  stdout.writeln('Python document round-trips through TournamentMapper.');
}
