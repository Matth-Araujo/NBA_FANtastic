class Player {
  final int id;
  final String fullName;
  final String position;
  final String teamName;
  final String teamAbbreviation;
  final double avgPoints;
  final double avgRebounds;
  final double avgAssists;
  final double avgSteals;
  final double avgBlocks;
  final String careerSpan;
  final int? age;
  final int? height;
  final String country;
  final int totalGames;
  final int totalPoints;
  final int totalRebounds;
  final int totalAssists;

  Player({
    required this.id,
    required this.fullName,
    this.position = '',
    this.teamName = '',
    this.teamAbbreviation = '',
    this.avgPoints = 0.0,
    this.avgRebounds = 0.0,
    this.avgAssists = 0.0,
    this.avgSteals = 0.0,
    this.avgBlocks = 0.0,
    this.careerSpan = '',
    this.age,
    this.height,
    this.country = '',
    this.totalGames = 0,
    this.totalPoints = 0,
    this.totalRebounds = 0,
    this.totalAssists = 0,
  });

  String get firstName => fullName.split(' ').first;
  String get lastName =>
      fullName.split(' ').length > 1
          ? fullName.split(' ').sublist(1).join(' ')
          : '';

  String get imageUrl =>
      id > 0 ? 'https://cdn.nba.com/headshots/nba/latest/260x190/$id.png' : '';

  int get seasonsCount {
    final matches = RegExp(r'\b(\d{4})\b')
        .allMatches(careerSpan)
        .map((m) => int.parse(m.group(1)!))
        .toList();
    if (matches.length >= 2) {
      final diff = matches.last - matches.first + 1;
      return diff > 0 ? diff : 1;
    } else if (matches.length == 1) {
      return 1;
    }
    return 0;
  }

  // Converte o JSON da API em Objeto Flutter
  factory Player.fromJson(Map<String, dynamic> json) {
    final career = json['career'] as Map<String, dynamic>?;
    final avg = career?['avg'] as Map<String, dynamic>?;
    final totals = career?['totals'] as Map<String, dynamic>?;
    final team = json['team'] as Map<String, dynamic>?;

    return Player(
      id: json['_id'] ?? json['id'] ?? 0,
      fullName: json['full_name'] ?? json['name'] ?? 'Desconhecido',
      position: json['position'] ?? '',
      teamName: team?['name'] ?? '',
      teamAbbreviation: team?['abbreviation'] ?? '',
      avgPoints: (avg?['points'] as num?)?.toDouble() ?? 0.0,
      avgRebounds: (avg?['rebounds'] as num?)?.toDouble() ?? 0.0,
      avgAssists: (avg?['assists'] as num?)?.toDouble() ?? 0.0,
      avgSteals: (avg?['steals'] as num?)?.toDouble() ?? 0.0,
      avgBlocks: (avg?['blocks'] as num?)?.toDouble() ?? 0.0,
      careerSpan: json['career_span'] ?? '',
      age: (json['age'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      country: json['country'] ?? '',
      totalGames: (totals?['games'] as num?)?.toInt() ?? 0,
      totalPoints: (totals?['points'] as num?)?.toInt() ?? 0,
      totalRebounds: (totals?['rebounds'] as num?)?.toInt() ?? 0,
      totalAssists: (totals?['assists'] as num?)?.toInt() ?? 0,
    );
  }
}
