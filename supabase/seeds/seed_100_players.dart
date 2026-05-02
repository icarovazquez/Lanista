#!/usr/bin/env dart
// ignore_for_file: avoid_print
/// Seeds 100 test players (50 male + 50 female) into the Lanista Supabase DB.
///
/// Usage:
///   dart run supabase/seeds/seed_100_players.dart <SERVICE_ROLE_KEY>
///
/// The service role key is required to create auth.users via the Admin API.
/// Find it in: Supabase Dashboard → Project Settings → API → service_role key

import 'dart:convert';
import 'dart:io';

const _supabaseUrl = 'https://yfyutdbxfwqajzsejenz.supabase.co';

// ── Reference UUIDs (from migration 018) ────────────────────────────────────

const _sportId = '00000000-0000-0000-0000-000000000001';

const _maleleagues = {
  'mls_next':   '10000000-0000-0000-0000-000000000001',
  'ecnl_boys':  '10000000-0000-0000-0000-000000000002',
  'ecrl':       '10000000-0000-0000-0000-000000000005',
  'npl_boys':   '10000000-0000-0000-0000-000000000006',
};

const _femaleLeagues = {
  'ecnl_girls': '10000000-0000-0000-0000-000000000003',
  'ga':         '10000000-0000-0000-0000-000000000004',
  'npl_girls':  '10000000-0000-0000-0000-000000000007',
};

const _maleClubs = {
  'la_galaxy':   '20000000-0000-0000-0000-000000000001',
  'nycfc':       '20000000-0000-0000-0000-000000000002',
  'chicago':     '20000000-0000-0000-0000-000000000003',
  'fc_dallas':   '20000000-0000-0000-0000-000000000004',
  'sounders':    '20000000-0000-0000-0000-000000000005',
  'ohio':        '20000000-0000-0000-0000-000000000007',
  'de_anza':     '20000000-0000-0000-0000-000000000008',
  'dal_texans':  '20000000-0000-0000-0000-000000000010',
};

const _femaleClubs = {
  'socal_blues': '20000000-0000-0000-0000-000000000006',
  'florida':     '20000000-0000-0000-0000-000000000009',
};

// ── Player data ───────────────────────────────────────────────────────────────

// Format: [firstName, lastName, email suffix]
const _maleNames = [
  ['Aiden', 'Walsh'],       ['Carlos', 'Mendoza'],   ['Jamal', 'Thompson'],
  ['Liam', 'Nguyen'],       ['Diego', 'Herrera'],     ['Tyler', 'Osei'],
  ['Mateo', 'Rivera'],      ['Jordan', 'Kim'],        ['Elijah', 'Patel'],
  ['Sebastián', 'Flores'],  ['Mason', 'Williams'],    ['Andrés', 'Torres'],
  ['Caleb', 'Jackson'],     ['Hugo', 'Martínez'],     ['Isaiah', 'Brown'],
  ['Nico', 'García'],       ['Ethan', 'Park'],        ['Kwame', 'Asante'],
  ['Finn', 'O\'Brien'],     ['Rafa', 'Jiménez'],      ['Zach', 'Miller'],
  ['Alex', 'Suárez'],       ['Trey', 'Johnson'],      ['Pablo', 'Castillo'],
  ['Jaden', 'Robinson'],    ['Cole', 'Wright'],        ['Darius', 'Evans'],
  ['Marco', 'Delgado'],     ['Ryan', 'Choi'],         ['Emre', 'Yıldız'],
  ['Bryce', 'Taylor'],      ['Óscar', 'Ramírez'],     ['Nate', 'Wilson'],
  ['Axel', 'Cruz'],         ['Kofi', 'Mensah'],       ['Hunter', 'Davis'],
  ['Tomás', 'Reyes'],       ['Marcus', 'Bell'],        ['Enzo', 'Russo'],
  ['Devon', 'Hughes'],      ['Kai', 'Tanaka'],        ['Julio', 'Vargas'],
  ['Trace', 'Moore'],       ['Rodrigo', 'Alves'],     ['Brennan', 'Scott'],
  ['Luis', 'Moreno'],       ['Chase', 'Peterson'],    ['Emilio', 'Sánchez'],
  ['Grant', 'Nelson'],      ['Ade', 'Adeyemi'],
];

const _femaleNames = [
  ['Aaliya', 'Okafor'],     ['Camila', 'Torres'],     ['Zoe', 'Chen'],
  ['Valentina', 'Reyes'],   ['Jada', 'Williams'],     ['Sienna', 'Park'],
  ['Mia', 'Gonzalez'],      ['Priya', 'Sharma'],      ['Amara', 'Diallo'],
  ['Lexi', 'Martinez'],     ['Grace', 'Thompson'],    ['Elena', 'Rossi'],
  ['Natalia', 'Fuentes'],   ['Brooklyn', 'Davis'],    ['Layla', 'Hassan'],
  ['Ximena', 'Morales'],    ['Avery', 'Johnson'],     ['Kira', 'Nakamura'],
  ['Destiny', 'Brown'],     ['Lucia', 'Herrera'],     ['Peyton', 'Clark'],
  ['Amelia', 'Nguyen'],     ['Sarai', 'Romero'],      ['Jade', 'Robinson'],
  ['Talia', 'Evans'],       ['Madison', 'Wilson'],    ['Sofía', 'Mendez'],
  ['Harper', 'Lee'],        ['Imani', 'Jackson'],     ['Addie', 'White'],
  ['Cassie', 'Taylor'],     ['Fernanda', 'Vega'],     ['Sydni', 'Anderson'],
  ['Nia', 'Owusu'],         ['Riley', 'Scott'],       ['Yara', 'Khalil'],
  ['Bri', 'Moore'],         ['Isabelle', 'Lambert'],  ['Paige', 'Miller'],
  ['Catalina', 'Rios'],     ['Autumn', 'Hughes'],     ['Kezia', 'Achebe'],
  ['Quinn', 'Barnes'],      ['Ingrid', 'Svensson'],   ['Alondra', 'Castillo'],
  ['Dani', 'Reed'],         ['Nadia', 'Kowalski'],    ['Simone', 'Foster'],
  ['Tess', 'Ortega'],       ['Ayasha', 'Runningwater'],
];

const _bios = [
  'Technically gifted with an explosive first step and great vision in tight spaces.',
  'High-motor player who tracks back and contributes on both ends of the pitch.',
  'Dominant in the air with excellent positioning and reading of the game.',
  'Quick feet and sharp decision-making make her dangerous in 1v1 situations.',
  'Press-resistant ball carrier with elite passing range and tactical intelligence.',
  'Clinical finisher with off-ball movement that consistently creates space.',
  'Strong in the tackle and composed in possession under pressure.',
  'Creative playmaker with the ability to unlock defenses with incisive passes.',
  'Tireless engine in midfield with a high work rate and consistent output.',
  'Aerial threat at both ends of the pitch with strong leadership qualities.',
  'Electric pace and dribbling ability in wide areas, dangerous in transition.',
  'Box-to-box player who reads the game early and rarely loses possession.',
  'Calm under pressure with excellent distribution from the back line.',
  'Natural goal scorer with excellent movement and a lethal finish.',
  'Versatile and adaptable — comfortable in multiple positions across the field.',
];

// Positions: abbreviation → UUID will be fetched at runtime
const _positionAbbrevs = [
  'GK', 'CB', 'CB', 'RB', 'LB',
  'CDM', 'CM', 'CM', 'CAM', 'RM',
  'LW', 'LW', 'RW', 'ST', 'ST',
];

// Secondary positions paired with primary (index-matched, some null)
const _secondaryPositions = [
  null, 'RB', 'LB', 'CDM', 'CDM',
  'CM', 'CAM', 'CDM', 'LW', 'RW',
  'CAM', 'ST', 'ST', 'LW', 'RW',
];

// ── HTTP helpers ─────────────────────────────────────────────────────────────
// Each helper creates its own HttpClient to avoid "stream already listened" issues.
// All use req.add(utf8.encode(...)) to properly handle Unicode (accented chars, em-dashes).

Map<String, String> _headers(String serviceKey, {String prefer = ''}) => {
  'Content-Type': 'application/json; charset=utf-8',
  'Authorization': 'Bearer $serviceKey',
  'apikey': serviceKey,
  if (prefer.isNotEmpty) 'Prefer': prefer,
};

Future<Map<String, dynamic>> _post(
  String url,
  Map<String, dynamic> body,
  String serviceKey,
) async {
  final client = HttpClient();
  try {
    final req = await client.postUrl(Uri.parse(url));
    _headers(serviceKey).forEach((k, v) => req.headers.set(k, v));
    req.add(utf8.encode(jsonEncode(body)));
    final res = await req.close();
    final data = await res.transform(utf8.decoder).join();
    return jsonDecode(data) as Map<String, dynamic>;
  } finally {
    client.close();
  }
}

Future<List<dynamic>> _getList(
  String url,
  String serviceKey,
) async {
  final client = HttpClient();
  try {
    final req = await client.getUrl(Uri.parse(url));
    _headers(serviceKey, prefer: 'return=representation')
        .forEach((k, v) => req.headers.set(k, v));
    final res = await req.close();
    final data = await res.transform(utf8.decoder).join();
    return jsonDecode(data) as List<dynamic>;
  } finally {
    client.close();
  }
}

/// POST/upsert that returns the first row (for getting generated IDs).
Future<Map<String, dynamic>> _postReturn(
  String url,
  Map<String, dynamic> body,
  String serviceKey,
) async {
  final client = HttpClient();
  try {
    final req = await client.postUrl(Uri.parse(url));
    _headers(serviceKey, prefer: 'return=representation,resolution=merge-duplicates')
        .forEach((k, v) => req.headers.set(k, v));
    req.add(utf8.encode(jsonEncode(body)));
    final res = await req.close();
    final data = await res.transform(utf8.decoder).join();
    if (res.statusCode >= 400) throw Exception('HTTP ${res.statusCode}: $data');
    final decoded = jsonDecode(data);
    if (decoded is List && decoded.isNotEmpty) return decoded.first as Map<String, dynamic>;
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Unexpected response: $data');
  } finally {
    client.close();
  }
}

Future<void> _postBatch(
  String url,
  List<Map<String, dynamic>> rows,
  String serviceKey,
) async {
  final client = HttpClient();
  try {
    final req = await client.postUrl(Uri.parse(url));
    _headers(serviceKey, prefer: 'return=minimal,resolution=merge-duplicates')
        .forEach((k, v) => req.headers.set(k, v));
    req.add(utf8.encode(jsonEncode(rows)));
    final res = await req.close();
    final respBody = await res.transform(utf8.decoder).join();
    if (res.statusCode >= 400) throw Exception('HTTP ${res.statusCode}: $respBody');
  } finally {
    client.close();
  }
}

// ── Main ──────────────────────────────────────────────────────────────────────

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart run supabase/seeds/seed_100_players.dart <SERVICE_ROLE_KEY>');
    exit(1);
  }
  final serviceKey = args[0];

  print('🌱 Fetching position UUIDs from DB...');

  // Fetch positions
  final positionsRaw = await _getList(
    '$_supabaseUrl/rest/v1/positions?select=id,abbreviation&sport_id=eq.$_sportId',
    serviceKey,
  );
  final posMap = <String, String>{
    for (final p in positionsRaw)
      (p['abbreviation'] as String): (p['id'] as String),
  };

  print('  Found positions: ${posMap.keys.join(', ')}');

  final maleLeagueList = _maleleagues.values.toList();
  final maleClubList = _maleClubs.values.toList();
  final femaleLeagueList = _femaleLeagues.values.toList();
  final femaleClubList = _femaleClubs.values.toList();

  final gradYears = [2025, 2026, 2027, 2028, 2029];
  final grades = [9, 10, 11, 12, 12];
  final divisions = ['D1', 'D1', 'D1', 'D2', 'D2', 'D3', 'NAIA'];
  final heights = [163, 168, 170, 173, 175, 176, 178, 180, 182, 185, 188];
  final weights = [57, 60, 63, 65, 68, 70, 72, 75, 78, 80];
  final gpas = [2.7, 2.9, 3.0, 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9];
  final feet = ['right', 'right', 'right', 'left', 'both'];
  final speeds = [5, 6, 7, 7, 8, 8, 9, 9, 10];

  int created = 0;
  int skipped = 0;

  Future<void> seedPlayer({
    required int index,
    required String firstName,
    required String lastName,
    required String gender,
    required String leagueId,
    required String clubId,
  }) async {
    final emailSlug =
        '${firstName.toLowerCase().replaceAll(RegExp(r"[^a-z]"), '')}.'
        '${lastName.toLowerCase().replaceAll(RegExp(r"[^a-z]"), '')}';
    final email = '$emailSlug.${index + 200}@lanista.test';
    final uid = 'a2${index.toString().padLeft(6, '0')}-0000-0000-0000-000000000000';

    final posIdx = index % _positionAbbrevs.length;
    final primaryAbbrev = _positionAbbrevs[posIdx];
    final secondaryAbbrev = _secondaryPositions[posIdx];
    final primaryPosId = posMap[primaryAbbrev];
    final secondaryPosId = secondaryAbbrev != null ? posMap[secondaryAbbrev] : null;

    if (primaryPosId == null) {
      print('  ⚠️  No position UUID for $primaryAbbrev — skipping $firstName $lastName');
      skipped++;
      return;
    }

    final gradYear = gradYears[index % gradYears.length];
    final grade = grades[index % grades.length];
    final division = divisions[index % divisions.length];
    final heightCm = heights[index % heights.length];
    final weightKg = weights[index % weights.length];
    final gpa = gpas[index % gpas.length];
    final foot = feet[index % feet.length];
    final speed = speeds[index % speeds.length];
    final bio = _bios[index % _bios.length];

    try {
      // 1. Create auth user
      final authRes = await _post(
        '$_supabaseUrl/auth/v1/admin/users',
        {
          'email': email,
          'password': 'Lanista2026!',
          'email_confirm': true,
          'id': uid,
          'user_metadata': {},
        },
        serviceKey,
      );

      if (authRes.containsKey('msg')) {
        final msg = authRes['msg']?.toString() ?? '';
        final isAlreadyExists = msg.contains('already') ||
            msg.contains('duplicate') ||
            (authRes['error_code'] as String? ?? '').contains('exists');
        if (!isAlreadyExists) {
          throw Exception('Auth error: $msg');
        }
        // Auth user already exists — fall through and upsert public.users + players anyway
      }

      // 2. Upsert public user (merge so first_name etc. always get set)
      await _postBatch(
        '$_supabaseUrl/rest/v1/users?on_conflict=id',
        [
          {
            'id': uid,
            'email': email,
            'role': 'player',
            'first_name': firstName,
            'last_name': lastName,
            'language': (index % 3 == 0) ? 'es' : 'en',
            'onboarding_complete': true,
          }
        ],
        serviceKey,
      );

      // 3. Insert player profile (upsert) — need return=representation to get id
      final playerRes = await _postReturn(
        '$_supabaseUrl/rest/v1/players?on_conflict=user_id',
        {
          'user_id': uid,
          'sport_id': _sportId,
          'gender': gender,
          'grade': grade,
          'graduation_year': gradYear,
          'height_cm': heightCm,
          'weight_kg': weightKg,
          'dominant_foot': foot,
          'speed_rating': speed,
          'gpa': gpa,
          'target_division': division,
          'is_discoverable': true,
          'leadership_rating': (index % 5) + 1,
          'club_id': clubId,
          'league_id': leagueId,
          'bio': bio,
        },
        serviceKey,
      );

      final playerId = playerRes['id'] as String?;
      if (playerId == null) {
        throw Exception('No player id returned: $playerRes');
      }

      // 4. Delete existing player_positions (idempotent re-run), then insert fresh
      {
        final delClient = HttpClient();
        try {
          final req = await delClient.deleteUrl(Uri.parse(
            '$_supabaseUrl/rest/v1/player_positions?player_id=eq.$playerId',
          ));
          _headers(serviceKey).forEach((k, v) => req.headers.set(k, v));
          final res = await req.close();
          await res.drain();
        } finally {
          delClient.close();
        }
      }
      final posRows = <Map<String, dynamic>>[
        {
          'player_id': playerId,
          'position_id': primaryPosId,
          'is_primary': true,
          'proficiency': 4,
        },
      ];
      if (secondaryPosId != null) {
        posRows.add({
          'player_id': playerId,
          'position_id': secondaryPosId,
          'is_primary': false,
          'proficiency': 3,
        });
      }

      await _postBatch(
        '$_supabaseUrl/rest/v1/player_positions',
        posRows,
        serviceKey,
      );

      created++;
      print('  ✅ [$created] $firstName $lastName ($gender, $primaryAbbrev, $gradYear, $division)');
    } catch (e) {
      print('  ❌ Error seeding $firstName $lastName: $e');
      skipped++;
    }
  }

  print('\n👦 Seeding 50 male players...');
  for (int i = 0; i < 50; i++) {
    final name = _maleNames[i];
    await seedPlayer(
      index: i,
      firstName: name[0],
      lastName: name[1],
      gender: 'male',
      leagueId: maleLeagueList[i % maleLeagueList.length],
      clubId: maleClubList[i % maleClubList.length],
    );
  }

  print('\n👧 Seeding 50 female players...');
  for (int i = 0; i < 50; i++) {
    final name = _femaleNames[i];
    await seedPlayer(
      index: i + 50,
      firstName: name[0],
      lastName: name[1],
      gender: 'female',
      leagueId: femaleLeagueList[i % femaleLeagueList.length],
      clubId: femaleClubList[i % femaleClubList.length],
    );
  }

  print('\n🏁 Done! Created: $created | Skipped/errors: $skipped');
  print('   Total in DB: 12 existing + $created new = ${12 + created} players');
}
