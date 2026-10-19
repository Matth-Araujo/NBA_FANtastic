import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nba_fantastic/Widgets/banner.dart';

import '../Widgets/section_title.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../player_model.dart';
import '../Widgets/player_card.dart';

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
      return 'http://127.0.0.1:8000';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    } else {
      return 'http://127.0.0.1:8000';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,

      //app Bar
      appBar: AppBar(
        backgroundColor: darkBg,
        elevation: 0,
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 32),
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
      ),

      //body
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HomeBanner(),
            const SizedBox(height: 24),

            const SectionTitle(title: 'TIMES', showSeeAll: true),
            const SizedBox(height: 16),

            const SizedBox(height: 24),

            const SectionTitle(
              title: 'LÍDERES DA TEMPORADA',
              showSeeAll: false,
            ),
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
      ),

      //botao de navegacao
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: navBg,
        // type: BottomNavigationBarType.fixed,
        selectedItemColor: brandOrange,
        unselectedItemColor: textGrey,
        currentIndex: _currentIndex,
        selectedFontSize: 12,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_outlined),
            label: 'Jogadores',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_outlined),
            label: 'Ranking',
          ),
        ],
      ),
    );
  }
}
