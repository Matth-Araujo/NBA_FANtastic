import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nba_fantastic/Widgets/banner.dart';

import 'dart:ui';

import '../Widgets/section_title.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../player_model.dart';
import '../Widgets/player_card.dart';

import 'player_detail_screen.dart';
import 'players_screen.dart';

class NbaFantasticScreen extends StatefulWidget {
  const NbaFantasticScreen({super.key});

  @override
  State<NbaFantasticScreen> createState() => _NbaFantasticScreenState();
}

class _NbaFantasticScreenState extends State<NbaFantasticScreen> {
  int _currentIndex = 0;

  final Color darkBg = const Color(0xFF121212);
  final Color navBg = const Color(0xFF000000);
  final Color brandOrange = const Color(0xFFFF6B00);
  final Color textGrey = const Color(0xFFA0A6B1);

  late Future<List<Player>> _playersFuture;

  @override
  void initState() {
    super.initState();
    _playersFuture = fetchPlayers();
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

  Future<List<Player>> fetchPlayers() async {
    final response = await http.get(Uri.parse('$_apiBaseUrl/players/?limit=3'));
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      final List items = data['data'] ?? [];

      return items.map((playerJson) => Player.fromJson(playerJson)).toList();
    } else {
      throw Exception(
        'Falha ao carregar jogadores da API: ${response.statusCode}',
      );
    }
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final bool isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 12.0,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? brandOrange.withValues(alpha: 0.16)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isSelected
                    ? brandOrange.withValues(alpha: 0.35)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? brandOrange : textGrey,
                  size: 23,
                  shadows: isSelected
                      ? [
                          Shadow(
                            color: brandOrange.withValues(alpha: 0.55),
                            blurRadius: 12,
                          ),
                        ]
                      : null,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? brandOrange : textGrey,
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 110.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeBanner(),
          const SizedBox(height: 24),

          const SectionTitle(title: 'TIMES', showSeeAll: true),
          const SizedBox(height: 16),

          const SizedBox(height: 24),

          const SectionTitle(title: 'LÍDERES DA TEMPORADA', showSeeAll: false),
          const SizedBox(height: 16),

          FutureBuilder<List<Player>>(
            future: _playersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.0),
                    child: CircularProgressIndicator(color: Colors.orange),
                  ),
                );
              } else if (snapshot.hasError) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1C20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Erro ao carregar dados:',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${snapshot.error}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _playersFuture = fetchPlayers();
                          });
                        },
                        icon: const Icon(Icons.refresh, color: Colors.orange),
                        label: const Text(
                          'Tentar novamente',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                );
              } else if (snapshot.hasData) {
                final players = snapshot.data!;

                if (players.isEmpty) {
                  return const Text(
                    'Nenhum jogador encontrado.',
                    style: TextStyle(color: Colors.white70),
                  );
                }

                final featuredPlayers = players.take(3).toList();

                return LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (int i = 0; i < featuredPlayers.length; i++)
                              Padding(
                                padding: EdgeInsets.only(
                                  left: i == 0 ? 0 : 6.0,
                                  right: i == featuredPlayers.length - 1
                                      ? 0
                                      : 6.0,
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PlayerDetailScreen(
                                          player: featuredPlayers[i],
                                        ),
                                      ),
                                    );
                                  },
                                  child: PlayerCard(
                                    name: featuredPlayers[i].fullName,
                                    pts:
                                        '${featuredPlayers[i].avgPoints.toStringAsFixed(1)} PTS',
                                    rebAst:
                                        '${featuredPlayers[i].avgRebounds.toStringAsFixed(1)} REB • ${featuredPlayers[i].avgAssists.toStringAsFixed(1)} AST',
                                    imageUrl:
                                        '$_apiBaseUrl/players/${featuredPlayers[i].id}/image',
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      extendBody: true,

      //app Bar
      appBar: _currentIndex == 0
          ? AppBar(
              backgroundColor: darkBg,
              elevation: 0,
              title: Row(
                children: [
                  Image.asset('assets/logo_sem_fundo.png', height: 32),
                  const SizedBox(width: 8),

                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Impact',
                      ),
                      children: [
                        const TextSpan(
                          text: 'NBA ',
                          style: TextStyle(color: Colors.white),
                        ),
                        TextSpan(
                          text: 'Fantastic',
                          style: TextStyle(color: brandOrange),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.search, color: Colors.white),
                ),
                IconButton(
                  onPressed: () {},
                  icon: Badge(
                    backgroundColor: brandOrange,
                    smallSize: 10,
                    child: const Icon(
                      Icons.notifications_none_outlined,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            )
          : null,

      //body
      body: _currentIndex == 0
          ? _buildHomeContent()
          : _currentIndex == 1
          ? const PlayersScreen()
          : const Center(
              child: Text(
                'Tela de Ranking',
                style: TextStyle(color: Colors.white),
              ),
            ),

      //botao de navegacao
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1.1,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1E2128).withValues(alpha: 0.85),
                      const Color(0xFF121418).withValues(alpha: 0.78),
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      index: 0,
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home_rounded,
                      label: 'Início',
                    ),
                    _buildNavItem(
                      index: 1,
                      icon: Icons.people_alt_outlined,
                      activeIcon: Icons.people_alt_rounded,
                      label: 'Jogadores',
                    ),
                    _buildNavItem(
                      index: 2,
                      icon: Icons.emoji_events_outlined,
                      activeIcon: Icons.emoji_events_rounded,
                      label: 'Ranking',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
