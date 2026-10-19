class Player {
  final int id;
  final String fullName;
  final String position;
  final String teamName;
  final String teamAbbreviation;
  final double avgPoints;
  final double avgRebounds;
  final double avgAssists;

  Player({
    required this.id,
    required this.fullName,
    this.position = '',
    this.teamName = '',
    this.teamAbbreviation = '',
    this.avgPoints = 0.0,
    this.avgRebounds = 0.0,
    this.avgAssists = 0.0,
  });

  String get firstName => fullName.split(' ').first;
  String get lastName =>
      fullName.split(' ').length > 1
          ? fullName.split(' ').sublist(1).join(' ')
          : '';

  String get imageUrl =>
      id > 0 ? 'https://cdn.nba.com/headshots/nba/latest/260x190/$id.png' : '';


  // Converte o JSON da API em Objeto Flutter
  factory Player.fromJson(Map<String, dynamic> json) {
    final career = json['career'] as Map<String, dynamic>?;
    final avg = career?['avg'] as Map<String, dynamic>?;
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
    );
  }
}
