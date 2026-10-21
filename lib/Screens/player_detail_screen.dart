import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../player_model.dart';

class PlayerDetailScreen extends StatefulWidget {
  final Player player;

  const PlayerDetailScreen({super.key, required this.player});

  @override
  State<PlayerDetailScreen> createState() => _PlayerDetailScreenState();
}

class _PlayerDetailScreenState extends State<PlayerDetailScreen> {
  // Caches estáticos em memória para navegação instantânea
  static List<Map<String, dynamic>>? _cachedTeams;
  static final Map<int, List<Map<String, dynamic>>> _cachedRecentGames = {};
  static final Map<int, Map<String, dynamic>> _cachedSeasonPredictions = {};

  final Color darkBg = const Color(0xFF0B0C0E);
  final Color cardBg = const Color(0xFF14161A);
  final Color brandOrange = const Color(0xFFFF6B00);
  final Color textGrey = const Color(0xFFA0A6B1);

  int _selectedTabIndex = 0;
  final List<String> _tabs = ['Visão geral', 'Predict', 'Carreira', 'Perfil'];

  Map<String, dynamic>? _fullPlayerData;

  // Estado dos últimos jogos reais da NBA
  List<Map<String, dynamic>> _recentGames = [];
  bool _isLoadingRecentGames = false;

  // Estado do Predict da Temporada (Marcel Projection)
  Map<String, dynamic>? _seasonPrediction;
  bool _isLoadingSeasonPrediction = false;

  // Estado do Simulador de Confronto (Predict Matchup)
  List<Map<String, dynamic>> _opponentTeams = [];
  Map<String, dynamic>? _selectedOpponent;
  bool _isHomeGame = true;
  bool _isLoadingPrediction = false;
  String? _predictionError;
  Map<String, dynamic>? _currentPrediction;

  // Cache local por combinação (opponentId_isHome)
  final Map<String, Map<String, dynamic>> _matchupCache = {};

  @override
  void initState() {
    super.initState();
    _fetchPlayerDetails();
    _initTeamsAndPredict();
    _fetchSeasonPrediction();
    _fetchRecentGames();
  }

  String get _apiBaseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api/v1';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api/v1';
    } else {
      return 'http://127.0.0.1:8000/api/v1';
    }
  }

  String _getTeamLogoUrl(String abbr) {
    final clean = abbr.trim().toUpperCase();
    if (clean.isEmpty) return '';
    const espnMap = {
      'UTA': 'utah',
      'NOP': 'no',
      'GSW': 'gs',
      'NYK': 'ny',
      'SAS': 'sa',
    };
    final code = espnMap[clean] ?? clean.toLowerCase();
    return 'https://a.espncdn.com/i/teamlogos/nba/500/$code.png';
  }

  Widget _buildTeamLogo(
    String abbr, {
    double size = 24,
    IconData fallbackIcon = Icons.sports_basketball,
    Color? fallbackColor,
  }) {
    final url = _getTeamLogoUrl(abbr);
    final color = fallbackColor ?? brandOrange;
    if (url.isEmpty) {
      return Icon(fallbackIcon, color: color, size: size * 0.78);
    }
    return Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          Icon(fallbackIcon, color: color, size: size * 0.78),
    );
  }

  Future<void> _fetchPlayerDetails() async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/players/${widget.player.id}'),
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _fullPlayerData = decoded['data'] ?? decoded;
          });
        }
      }
    } catch (_) {
      // Mantém os dados já carregados no objeto Player
    }
  }

  Future<void> _fetchSeasonPrediction() async {
    final playerId = widget.player.id;
    if (_cachedSeasonPredictions.containsKey(playerId)) {
      setState(() {
        _seasonPrediction = _cachedSeasonPredictions[playerId];
        _isLoadingSeasonPrediction = false;
      });
      return;
    }

    setState(() {
      _isLoadingSeasonPrediction = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/players/$playerId/predictions/season'),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = Map<String, dynamic>.from(
          (decoded['data'] ?? decoded) as Map,
        );
        _cachedSeasonPredictions[playerId] = data;
        setState(() {
          _seasonPrediction = data;
          _isLoadingSeasonPrediction = false;
        });
      } else {
        setState(() {
          _isLoadingSeasonPrediction = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingSeasonPrediction = false;
        });
      }
    }
  }

  Future<void> _fetchRecentGames() async {
    final playerId = widget.player.id;
    if (_cachedRecentGames.containsKey(playerId)) {
      setState(() {
        _recentGames = _cachedRecentGames[playerId]!;
        _isLoadingRecentGames = false;
      });
      return;
    }

    setState(() {
      _isLoadingRecentGames = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/players/$playerId/recent-games?limit=4'),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List rawGames = decoded['data'] ?? [];
        final gamesList = rawGames
            .map((g) => Map<String, dynamic>.from(g as Map))
            .toList();
        if (gamesList.isNotEmpty) {
          _cachedRecentGames[playerId] = gamesList;
        }
        setState(() {
          _recentGames = gamesList;
          _isLoadingRecentGames = false;
        });
      } else {
        setState(() {
          _isLoadingRecentGames = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingRecentGames = false;
        });
      }
    }
  }

  Future<void> _initTeamsAndPredict() async {
    try {
      if (_cachedTeams == null || _cachedTeams!.isEmpty) {
        final response = await http.get(
          Uri.parse('$_apiBaseUrl/teams/?limit=30'),
        );
        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          final List rawTeams = decoded['data'] ?? [];
          final teamsList = rawTeams
              .map((t) => Map<String, dynamic>.from(t as Map))
              .toList();
          teamsList.sort(
            (a, b) => (a['name'] ?? '').toString().compareTo(
              (b['name'] ?? '').toString(),
            ),
          );
          _cachedTeams = teamsList;
        }
      }

      if (!mounted) return;

      final allTeams = _cachedTeams ?? [];
      final filtered = allTeams.where((t) {
        final abb = (t['abbreviation'] ?? '').toString().toUpperCase();
        return abb.isNotEmpty &&
            abb != widget.player.teamAbbreviation.toUpperCase();
      }).toList();

      setState(() {
        _opponentTeams = filtered.isNotEmpty ? filtered : allTeams;
        if (_opponentTeams.isNotEmpty) {
          _selectedOpponent = _opponentTeams.first;
        }
      });

      if (_selectedOpponent != null) {
        await _fetchMatchupPrediction();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _predictionError = 'Não foi possível carregar os times da API.';
        });
      }
    }
  }

  Future<void> _fetchMatchupPrediction() async {
    final opponent = _selectedOpponent;
    if (opponent == null) return;

    final int? opponentId =
        (opponent['_id'] as num?)?.toInt() ?? (opponent['id'] as num?)?.toInt();
    if (opponentId == null) return;

    final cacheKey = '${opponentId}_$_isHomeGame';
    if (_matchupCache.containsKey(cacheKey)) {
      setState(() {
        _currentPrediction = _matchupCache[cacheKey];
        _predictionError = null;
        _isLoadingPrediction = false;
      });
      return;
    }

    setState(() {
      _isLoadingPrediction = true;
      _predictionError = null;
    });

    try {
      final uri = Uri.parse(
        '$_apiBaseUrl/players/${widget.player.id}/predictions/matchup/$opponentId?is_home=$_isHomeGame',
      );
      final response = await http.get(uri);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = Map<String, dynamic>.from(
          (decoded['data'] ?? decoded) as Map,
        );
        _matchupCache[cacheKey] = data;
        setState(() {
          _currentPrediction = data;
          _isLoadingPrediction = false;
        });
      } else {
        setState(() {
          _predictionError =
              'Erro ao calcular predição (${response.statusCode})';
          _isLoadingPrediction = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _predictionError = 'Falha de conexão ao calcular predição.';
          _isLoadingPrediction = false;
        });
      }
    }
  }

  void _openTeamPickerModal() {
    if (_opponentTeams.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121418),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          maxChildSize: 0.88,
          minChildSize: 0.4,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  child: Text(
                    'Selecionar Adversário',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(color: Colors.white10, height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: _opponentTeams.length,
                    itemBuilder: (context, index) {
                      final team = _opponentTeams[index];
                      final isSelected =
                          team['_id'] == _selectedOpponent?['_id'];
                      final abb = (team['abbreviation'] ?? '').toString();
                      final name = (team['name'] ?? '').toString();
                      final conf = (team['conference'] ?? '').toString();

                      return ListTile(
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _selectedOpponent = team;
                          });
                          _fetchMatchupPrediction();
                        },
                        leading: Container(
                          width: 42,
                          height: 42,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? brandOrange.withValues(alpha: 0.2)
                                : const Color(0xFF1E2128),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? brandOrange : Colors.white12,
                            ),
                          ),
                          child: _buildTeamLogo(abb, size: 28),
                        ),
                        title: Text(
                          '$name ($abb)',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                        subtitle: conf.isNotEmpty
                            ? Text(
                                'Conferência ${conf == "East" ? "Leste" : "Oeste"}',
                                style: TextStyle(color: textGrey, fontSize: 12),
                              )
                            : null,
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: brandOrange)
                            : null,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _translatePosition(String apiPosition) {
    final pos = apiPosition.toLowerCase().trim();
    if (pos.contains('guard') && pos.contains('forward')) return 'Ala-Armador';
    if (pos.contains('forward') && pos.contains('center')) return 'Ala-Pivô';
    if (pos == 'pg' ||
        pos.contains('point guard') ||
        pos == 'g' ||
        pos.contains('guard')) {
      return 'Armador';
    }
    if (pos == 'sg' || pos.contains('shooting guard')) return 'Ala-Armador';
    if (pos == 'sf' ||
        pos.contains('small forward') ||
        pos == 'f' ||
        pos.contains('forward')) {
      return 'Ala';
    }
    if (pos == 'pf' || pos.contains('power forward')) return 'Ala-Pivô';
    if (pos == 'c' || pos.contains('center')) return 'Pivô';
    return apiPosition.isNotEmpty ? apiPosition : 'Ala';
  }

  @override
  Widget build(BuildContext context) {
    final career = _fullPlayerData?['career'] as Map<String, dynamic>?;
    final avg = career?['avg'] as Map<String, dynamic>?;
    final totals = career?['totals'] as Map<String, dynamic>?;

    final double ppg =
        (avg?['points'] as num?)?.toDouble() ?? widget.player.avgPoints;
    final double rpg =
        (avg?['rebounds'] as num?)?.toDouble() ?? widget.player.avgRebounds;
    final double apg =
        (avg?['assists'] as num?)?.toDouble() ?? widget.player.avgAssists;
    final double spg =
        (avg?['steals'] as num?)?.toDouble() ?? widget.player.avgSteals;
    final double bpg =
        (avg?['blocks'] as num?)?.toDouble() ?? widget.player.avgBlocks;

    final int gamesPlayed =
        (totals?['games'] as num?)?.toInt() ?? widget.player.totalGames;
    final int totalPts =
        (totals?['points'] as num?)?.toInt() ?? widget.player.totalPoints;
    final int totalReb =
        (totals?['rebounds'] as num?)?.toInt() ?? widget.player.totalRebounds;
    final int totalAst =
        (totals?['assists'] as num?)?.toInt() ?? widget.player.totalAssists;

    final int? playerAge =
        (_fullPlayerData?['age'] as num?)?.toInt() ?? widget.player.age;
    final int? playerHeight =
        (_fullPlayerData?['height'] as num?)?.toInt() ?? widget.player.height;
    final String playerCountry =
        (_fullPlayerData?['country'] as String?) ?? widget.player.country;
    final String careerSpan =
        (_fullPlayerData?['career_span'] as String?) ??
        widget.player.careerSpan;

    final String highResImageUrl =
        '$_apiBaseUrl/players/${widget.player.id}/image?high_res=true';
    final String fallbackApiImageUrl =
        '$_apiBaseUrl/players/${widget.player.id}/image';

    return Scaffold(
      backgroundColor: darkBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. TOPO COM IMAGEM DE FUNDO (fundo_jogador.jpeg) + FOTO DO JOGADOR
            SizedBox(
              height: 335,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/fundo_jogador.jpeg',
                    fit: BoxFit.cover,
                    color: Colors.black.withValues(alpha: 0.35),
                    colorBlendMode: BlendMode.darken,
                  ),

                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0.0, -0.15),
                        radius: 0.95,
                        colors: [
                          brandOrange.withValues(alpha: 0.22),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  Positioned(
                    top: 38,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Image.network(
                      highResImageUrl,
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.network(
                          fallbackApiImageUrl,
                          fit: BoxFit.contain,
                          alignment: Alignment.bottomCenter,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.person,
                                size: 140,
                                color: Colors.white24,
                              ),
                        );
                      },
                    ),
                  ),

                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 0.42, 0.80, 1.0],
                          colors: [
                            Colors.black.withValues(alpha: 0.45),
                            Colors.transparent,
                            darkBg.withValues(alpha: 0.88),
                            darkBg,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Botão Superior (Apenas Voltar)
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 6.0,
                        ),
                        child: IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withValues(
                              alpha: 0.45,
                            ),
                          ),
                          icon: const Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                            size: 30,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  ),

                  // Logo + Sigla do Time na direita
                  if (widget.player.teamAbbreviation.isNotEmpty)
                    Positioned(
                      right: 16,
                      top: 52,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: brandOrange.withValues(alpha: 0.45),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildTeamLogo(
                              widget.player.teamAbbreviation,
                              size: 24,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.player.teamAbbreviation,
                              style: TextStyle(
                                color: brandOrange,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Nome do Jogador e Subtítulo
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.player.fullName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_translatePosition(widget.player.position)}  •  ${widget.player.teamName.isNotEmpty ? widget.player.teamName : "NBA"}${playerAge != null ? "  •  $playerAge anos" : ""}',
                          style: TextStyle(
                            color: textGrey,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. BARRA DE ABAS (Visão geral | Predict | Carreira | Perfil)
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.white12, width: 1),
                ),
              ),
              child: Row(
                children: List.generate(_tabs.length, (index) {
                  final isSelected = _selectedTabIndex == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTabIndex = index;
                        });
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: isSelected
                                  ? brandOrange
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Text(
                          _tabs[index],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? Colors.white : textGrey,
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // 3. CONTEÚDO DA ABA SELECIONADA
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildSelectedTabContent(
                ppg: ppg,
                rpg: rpg,
                apg: apg,
                spg: spg,
                bpg: bpg,
                gamesPlayed: gamesPlayed,
                totalPts: totalPts,
                totalReb: totalReb,
                totalAst: totalAst,
                playerAge: playerAge,
                playerHeight: playerHeight,
                playerCountry: playerCountry,
                careerSpan: careerSpan,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedTabContent({
    required double ppg,
    required double rpg,
    required double apg,
    required double spg,
    required double bpg,
    required int gamesPlayed,
    required int totalPts,
    required int totalReb,
    required int totalAst,
    required int? playerAge,
    required int? playerHeight,
    required String playerCountry,
    required String careerSpan,
  }) {
    if (_selectedTabIndex == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // GRADE 3x2 DE ESTATÍSTICAS MÉDIAS
          Row(
            children: [
              _buildStatBox(ppg.toStringAsFixed(1), 'PPG'),
              const SizedBox(width: 10),
              _buildStatBox(rpg.toStringAsFixed(1), 'RPG'),
              const SizedBox(width: 10),
              _buildStatBox(apg.toStringAsFixed(1), 'APG'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildStatBox(spg.toStringAsFixed(1), 'SPG'),
              const SizedBox(width: 10),
              _buildStatBox(bpg.toStringAsFixed(1), 'BPG'),
              const SizedBox(width: 10),
              _buildStatBox('$gamesPlayed', 'JOGOS'),
            ],
          ),
          const SizedBox(height: 24),

          // SIMULADOR DE CONFRONTO (PREDICT CONTRA TIME + CASA/FORA)
          _buildMatchupPredictorSection(
            basePpg: ppg,
            baseRpg: rpg,
            baseApg: apg,
            baseSpg: spg,
            baseBpg: bpg,
          ),

          const SizedBox(height: 20),

          // PREDICT DA TEMPORADA (MARCEL PROJECTION)
          _buildSeasonPredictionSection(
            basePpg: ppg,
            baseRpg: rpg,
            baseApg: apg,
            baseSpg: spg,
            baseBpg: bpg,
          ),

          const SizedBox(height: 24),

          // ÚLTIMOS JOGOS REAIS COM LOGO DO TIME
          _buildRecentGamesSection(ppg: ppg, rpg: rpg, apg: apg),
        ],
      );
    } else if (_selectedTabIndex == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMatchupPredictorSection(
            basePpg: ppg,
            baseRpg: rpg,
            baseApg: apg,
            baseSpg: spg,
            baseBpg: bpg,
          ),
          const SizedBox(height: 20),
          _buildSeasonPredictionSection(
            basePpg: ppg,
            baseRpg: rpg,
            baseApg: apg,
            baseSpg: spg,
            baseBpg: bpg,
          ),
        ],
      );
    } else if (_selectedTabIndex == 2) {
      return _buildCareerSection(
        gamesPlayed: gamesPlayed,
        totalPts: totalPts,
        totalReb: totalReb,
        totalAst: totalAst,
        careerSpan: careerSpan,
      );
    } else {
      return _buildProfileSection(
        playerAge: playerAge,
        playerHeight: playerHeight,
        playerCountry: playerCountry,
        careerSpan: careerSpan,
      );
    }
  }

  Widget _buildSeasonPredictionSection({
    required double basePpg,
    required double baseRpg,
    required double baseApg,
    required double baseSpg,
    required double baseBpg,
  }) {
    final projected =
        _seasonPrediction?['projected_averages'] as Map<String, dynamic>?;
    final intervals =
        _seasonPrediction?['confidence_intervals'] as Map<String, dynamic>?;
    final params = _seasonPrediction?['params'] as Map<String, dynamic>?;

    final double sPts = (projected?['pts'] as num?)?.toDouble() ?? basePpg;
    final double sReb = (projected?['reb'] as num?)?.toDouble() ?? baseRpg;
    final double sAst = (projected?['ast'] as num?)?.toDouble() ?? baseApg;
    final double sStl = (projected?['stl'] as num?)?.toDouble() ?? baseSpg;
    final double sBlk = (projected?['blk'] as num?)?.toDouble() ?? baseBpg;

    final String ageFactorPct =
        (params?['age_adjustment_pct'] ?? '100%').toString();
    final int? ageParam = (params?['age'] as num?)?.toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF13161C),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.insights_rounded,
                      color: Colors.amber,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Predict da Temporada',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Projeção anual (Marcel Projection)',
                        style: TextStyle(
                          color: Color(0xFFA0A6B1),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  ageParam != null
                      ? '$ageParam anos • Fator $ageFactorPct'
                      : 'Fator $ageFactorPct',
                  style: const TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingSeasonPrediction)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(
                  color: brandOrange,
                  strokeWidth: 2.5,
                ),
              ),
            )
          else ...[
            Row(
              children: [
                _buildPredictionMainCard(
                  label: 'PTS / JOGO',
                  value: sPts,
                  baseline: basePpg,
                  range: intervals?['pts_range'],
                  isPrimary: true,
                ),
                const SizedBox(width: 8),
                _buildPredictionMainCard(
                  label: 'REB / JOGO',
                  value: sReb,
                  baseline: baseRpg,
                  range: intervals?['reb_range'],
                ),
                const SizedBox(width: 8),
                _buildPredictionMainCard(
                  label: 'AST / JOGO',
                  value: sAst,
                  baseline: baseApg,
                  range: intervals?['ast_range'],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildMiniPredRow(
                    label: 'Roubos (STL)',
                    value: sStl.toStringAsFixed(1),
                    range: _formatRange(intervals?['stl_range']),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMiniPredRow(
                    label: 'Tocos (BLK)',
                    value: sBlk.toStringAsFixed(1),
                    range: _formatRange(intervals?['blk_range']),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMatchupPredictorSection({
    required double basePpg,
    required double baseRpg,
    required double baseApg,
    required double baseSpg,
    required double baseBpg,
  }) {
    final projected =
        _currentPrediction?['projected_averages'] as Map<String, dynamic>?;
    final intervals =
        _currentPrediction?['confidence_intervals'] as Map<String, dynamic>?;
    final factors = _currentPrediction?['factors'] as Map<String, dynamic>?;
    final defFactors = factors?['defense_factors'] as Map<String, dynamic>?;

    final double predPts = (projected?['pts'] as num?)?.toDouble() ?? basePpg;
    final double predReb = (projected?['reb'] as num?)?.toDouble() ?? baseRpg;
    final double predAst = (projected?['ast'] as num?)?.toDouble() ?? baseApg;
    final double predStl = (projected?['stl'] as num?)?.toDouble() ?? baseSpg;
    final double predBlk = (projected?['blk'] as num?)?.toDouble() ?? baseBpg;

    final double paceFactor =
        (factors?['pace_factor'] as num?)?.toDouble() ?? 1.0;
    final double defPtsFactor =
        (defFactors?['pts'] as num?)?.toDouble() ?? 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1612), Color(0xFF121418)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: brandOrange.withValues(alpha: 0.45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho do Predict
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: brandOrange.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.auto_graph_rounded,
                      color: brandOrange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Predict de Confronto',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Projeção por adversário e mando de quadra',
                        style: TextStyle(
                          color: Color(0xFFA0A6B1),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (_opponentTeams.isNotEmpty)
                TextButton(
                  onPressed: _openTeamPickerModal,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Ver todos',
                    style: TextStyle(
                      color: brandOrange,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Seletor de Mando de Quadra (Dentro de Casa vs Fora de Casa)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0F12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                _buildVenueOption(
                  label: 'Dentro de Casa',
                  icon: Icons.home_rounded,
                  isSelected: _isHomeGame,
                  onTap: () {
                    if (!_isHomeGame) {
                      setState(() {
                        _isHomeGame = true;
                      });
                      _fetchMatchupPrediction();
                    }
                  },
                ),
                _buildVenueOption(
                  label: 'Fora de Casa',
                  icon: Icons.flight_takeoff_rounded,
                  isSelected: !_isHomeGame,
                  onTap: () {
                    if (_isHomeGame) {
                      setState(() {
                        _isHomeGame = false;
                      });
                      _fetchMatchupPrediction();
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Seletor horizontal rápido de times adversários com logo
          if (_opponentTeams.isNotEmpty)
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _opponentTeams.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final team = _opponentTeams[index];
                  final isSelected = team['_id'] == _selectedOpponent?['_id'];
                  final abb = (team['abbreviation'] ?? '').toString();
                  final city = (team['city'] ?? '').toString();

                  return GestureDetector(
                    onTap: () {
                      if (!isSelected) {
                        setState(() {
                          _selectedOpponent = team;
                        });
                        _fetchMatchupPrediction();
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? brandOrange
                            : const Color(0xFF181B20),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? brandOrange : Colors.white12,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTeamLogo(abb, size: 22),
                          const SizedBox(width: 6),
                          Text(
                            '$abb • $city',
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 16),

          // Confronto Selecionado com logos dos times
          if (_selectedOpponent != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  _buildTeamLogo(widget.player.teamAbbreviation, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${widget.player.teamAbbreviation.isNotEmpty ? widget.player.teamAbbreviation : "JOG"} vs ${_selectedOpponent!['name']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  _buildTeamLogo(
                    (_selectedOpponent!['abbreviation'] ?? '').toString(),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: (_isHomeGame ? Colors.green : Colors.amber)
                          .withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _isHomeGame ? 'Em Casa' : 'Fora',
                      style: TextStyle(
                        color: _isHomeGame
                            ? Colors.greenAccent
                            : Colors.amberAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Corpo do resultado da predição
          if (_isLoadingPrediction)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: CircularProgressIndicator(
                  color: brandOrange,
                  strokeWidth: 2.5,
                ),
              ),
            )
          else if (_predictionError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      _predictionError!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _fetchMatchupPrediction,
                      icon: Icon(Icons.refresh, color: brandOrange, size: 18),
                      label: Text(
                        'Tentar novamente',
                        style: TextStyle(color: brandOrange),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_currentPrediction != null) ...[
            Row(
              children: [
                _buildPredictionMainCard(
                  label: 'PONTOS',
                  value: predPts,
                  baseline: basePpg,
                  range: intervals?['pts_range'],
                  isPrimary: true,
                ),
                const SizedBox(width: 8),
                _buildPredictionMainCard(
                  label: 'REBOTES',
                  value: predReb,
                  baseline: baseRpg,
                  range: intervals?['reb_range'],
                ),
                const SizedBox(width: 8),
                _buildPredictionMainCard(
                  label: 'ASSIST.',
                  value: predAst,
                  baseline: baseApg,
                  range: intervals?['ast_range'],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildMiniPredRow(
                    label: 'Roubos (STL)',
                    value: predStl.toStringAsFixed(1),
                    range: _formatRange(intervals?['stl_range']),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMiniPredRow(
                    label: 'Tocos (BLK)',
                    value: predBlk.toStringAsFixed(1),
                    range: _formatRange(intervals?['blk_range']),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0E1014),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildFactorBadge(
                    label: 'Ritmo (Pace)',
                    value: '${paceFactor.toStringAsFixed(2)}x',
                    isPositive: paceFactor >= 1.0,
                  ),
                  Container(width: 1, height: 24, color: Colors.white12),
                  _buildFactorBadge(
                    label: 'Fator Defesa Adv.',
                    value: '${defPtsFactor.toStringAsFixed(2)}x',
                    isPositive: defPtsFactor >= 1.0,
                  ),
                  Container(width: 1, height: 24, color: Colors.white12),
                  _buildFactorBadge(
                    label: 'Ajuste Casa/Fora',
                    value: _isHomeGame ? '+1.2 PTS' : '-1.2 PTS',
                    isPositive: _isHomeGame,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVenueOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? brandOrange : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: isSelected ? Colors.black : textGrey),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatRange(dynamic rawRange) {
    if (rawRange is List && rawRange.length >= 2) {
      final minVal = (rawRange[0] as num).toDouble().toStringAsFixed(1);
      final maxVal = (rawRange[1] as num).toDouble().toStringAsFixed(1);
      return '$minVal – $maxVal';
    }
    return '';
  }

  Widget _buildPredictionMainCard({
    required String label,
    required double value,
    required double baseline,
    required dynamic range,
    bool isPrimary = false,
  }) {
    final double diff = value - baseline;
    final bool isUp = diff >= 0;
    final String diffText = '${isUp ? "+" : ""}${diff.toStringAsFixed(1)}';
    final String rangeText = _formatRange(range);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isPrimary
              ? brandOrange.withValues(alpha: 0.14)
              : const Color(0xFF16191F),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPrimary
                ? brandOrange.withValues(alpha: 0.5)
                : Colors.white10,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? brandOrange : textGrey,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value.toStringAsFixed(1),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (isUp ? Colors.green : Colors.amber).withValues(
                  alpha: 0.16,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$diffText vs média',
                style: TextStyle(
                  color: isUp ? Colors.greenAccent : Colors.amberAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (rangeText.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Faixa: $rangeText',
                style: TextStyle(
                  color: textGrey.withValues(alpha: 0.85),
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMiniPredRow({
    required String label,
    required String value,
    required String range,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF16191F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: textGrey,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (range.isNotEmpty)
                Text(
                  'Faixa: $range',
                  style: TextStyle(
                    color: textGrey.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactorBadge({
    required String label,
    required String value,
    required bool isPositive,
  }) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: textGrey, fontSize: 10.5)),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: isPositive ? Colors.greenAccent : Colors.amberAccent,
            fontWeight: FontWeight.w800,
            fontSize: 12.5,
          ),
        ),
      ],
    );
  }

  Widget _buildCareerSection({
    required int gamesPlayed,
    required int totalPts,
    required int totalReb,
    required int totalAst,
    required String careerSpan,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Totais acumulados na carreira',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (careerSpan.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Período ativo: $careerSpan (${widget.player.seasonsCount} temporadas)',
              style: TextStyle(color: textGrey, fontSize: 13),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatBox('$gamesPlayed', 'JOGOS'),
              const SizedBox(width: 10),
              _buildStatBox('$totalPts', 'PONTOS'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildStatBox('$totalReb', 'REBOTES'),
              const SizedBox(width: 10),
              _buildStatBox('$totalAst', 'ASSISTÊNCIAS'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection({
    required int? playerAge,
    required int? playerHeight,
    required String playerCountry,
    required String careerSpan,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          _buildProfileRow('Nome completo', widget.player.fullName),
          const Divider(color: Colors.white10),
          _buildProfileRow(
            'Equipe atual',
            widget.player.teamName.isNotEmpty
                ? '${widget.player.teamName} (${widget.player.teamAbbreviation})'
                : 'NBA',
          ),
          const Divider(color: Colors.white10),
          _buildProfileRow(
            'Posição',
            _translatePosition(widget.player.position),
          ),
          const Divider(color: Colors.white10),
          _buildProfileRow(
            'Idade',
            playerAge != null ? '$playerAge anos' : 'N/A',
          ),
          const Divider(color: Colors.white10),
          _buildProfileRow(
            'Altura',
            playerHeight != null ? '$playerHeight cm' : 'N/A',
          ),
          const Divider(color: Colors.white10),
          _buildProfileRow(
            'País de origem',
            playerCountry.isNotEmpty ? playerCountry : 'N/A',
          ),
          const Divider(color: Colors.white10),
          _buildProfileRow(
            'Temporadas na NBA',
            careerSpan.isNotEmpty
                ? '$careerSpan (${widget.player.seasonsCount})'
                : 'N/A',
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: textGrey, fontSize: 14)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: textGrey,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentGamesSection({
    required double ppg,
    required double rpg,
    required double apg,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Últimos jogos',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF141619),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white10),
          ),
          child: _isLoadingRecentGames
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: brandOrange,
                      strokeWidth: 2.5,
                    ),
                  ),
                )
              : _recentGames.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'Nenhum jogo recente registrado.',
                          style: TextStyle(color: textGrey, fontSize: 13),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        for (int i = 0; i < _recentGames.length; i++) ...[
                          if (i > 0)
                            const Divider(color: Colors.white10, height: 1),
                          Builder(
                            builder: (context) {
                              final game = _recentGames[i];
                              final int pts =
                                  (game['pts'] as num?)?.toInt() ?? 0;
                              final int reb =
                                  (game['reb'] as num?)?.toInt() ?? 0;
                              final int ast =
                                  (game['ast'] as num?)?.toInt() ?? 0;
                              final String matchup = (game['matchup'] ?? '')
                                  .toString()
                                  .replaceAll('@', 'vs');
                              final String oppAbbr =
                                  (game['opponent_abbr'] ?? '').toString();
                              final String date =
                                  (game['date'] ?? '').toString();

                              return _buildGameRow(
                                teamAbbr: oppAbbr.isNotEmpty
                                    ? oppAbbr
                                    : widget.player.teamAbbreviation,
                                matchup: matchup,
                                subStats: '$pts PTS  $reb REB  $ast AST',
                                mainPts: '$pts',
                                mainAst: '$ast',
                                date: date,
                              );
                            },
                          ),
                        ],
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _buildGameRow({
    required String teamAbbr,
    required String matchup,
    required String subStats,
    required String mainPts,
    required String mainAst,
    required String date,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1E2128),
              border: Border.all(color: Colors.white12),
            ),
            child: _buildTeamLogo(teamAbbr, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  matchup,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subStats,
                  style: TextStyle(
                    color: textGrey.withValues(alpha: 0.75),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$mainPts ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                TextSpan(
                  text: 'PTS   ',
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: '$mainAst ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                TextSpan(
                  text: 'AST',
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Text(
            date,
            style: TextStyle(
              color: textGrey,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
