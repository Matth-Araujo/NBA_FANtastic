import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../player_model.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  final Color darkBg = const Color(0xFF0B0C0E);
  final Color cardBg = const Color(0xFF141619);
  final Color brandOrange = const Color(0xFFFF6B00);
  final Color textGrey = const Color(0xFFA0A6B1);

  final List<String> _filters = ['Todos', 'Armadores', 'Alas', 'Pivôs'];
  int _selectedFilterIndex = 0;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _sortOptions = [
    'Nome (A–Z)',
    'Pontos por jogo (PTS)',
    'Assistências por jogo (AST)',
    'Rebotes por jogo (REB)',
    'Mais temporadas registradas',
  ];
  String _selectedSort = 'Pontos por jogo (PTS)';

  late Future<List<Player>> _playersFuture;

  @override
  void initState() {
    super.initState();
    _playersFuture = fetchAllPlayers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Future<List<Player>> fetchAllPlayers() async {
    final firstResponse = await http.get(
      Uri.parse('$_apiBaseUrl/players/?page=1&limit=100'),
    );

    if (firstResponse.statusCode != 200) {
      throw Exception(
        'Falha ao carregar jogadores: ${firstResponse.statusCode}',
      );
    }

    final Map<String, dynamic> firstData = jsonDecode(firstResponse.body);
    final List allItems = List.from(firstData['data'] ?? []);
    final int totalPages =
        (firstData['pagination']?['total_pages'] as num?)?.toInt() ?? 1;

    if (totalPages > 1) {
      final remainingResponses = await Future.wait(
        List.generate(
          totalPages - 1,
          (i) => http.get(
            Uri.parse('$_apiBaseUrl/players/?page=${i + 2}&limit=100'),
          ),
        ),
      );

      for (final response in remainingResponses) {
        if (response.statusCode == 200) {
          final Map<String, dynamic> pageData = jsonDecode(response.body);
          allItems.addAll(pageData['data'] ?? []);
        }
      }
    }

    return allItems.map((playerJson) => Player.fromJson(playerJson)).toList();
  }

  bool _matchesPositionFilter(String apiPosition, int filterIndex) {
    if (filterIndex == 0) return true;

    final pos = apiPosition.toLowerCase();

    if (filterIndex == 1) {
      return pos.contains('guard') ||
          pos == 'g' ||
          pos == 'pg' ||
          pos == 'sg' ||
          pos.startsWith('g-') ||
          pos.endsWith('-g') ||
          pos.contains('armador');
    } else if (filterIndex == 2) {
      return pos.contains('forward') ||
          pos == 'f' ||
          pos == 'sf' ||
          pos == 'pf' ||
          pos.startsWith('f-') ||
          pos.endsWith('-f') ||
          pos.contains('ala');
    } else if (filterIndex == 3) {
      return pos.contains('center') ||
          pos == 'c' ||
          pos.startsWith('c-') ||
          pos.endsWith('-c') ||
          pos.contains('piv');
    }
    return true;
  }

  String _formatPositionLine(String apiPosition) {
    final pos = apiPosition.toLowerCase().trim();
    if (pos.contains('guard') && pos.contains('forward')) {
      return 'G-F • Ala-armador';
    }
    if (pos.contains('forward') && pos.contains('center')) {
      return 'F-C • Ala-pivô';
    }
    if (pos == 'pg' || pos.contains('point guard')) return 'PG • Armador';
    if (pos == 'sg' || pos.contains('shooting guard')) {
      return 'SG • Ala-armador';
    }
    if (pos == 'sf' || pos.contains('small forward')) return 'SF • Ala';
    if (pos == 'pf' || pos.contains('power forward')) return 'PF • Ala-pivô';
    if (pos.contains('guard') || pos == 'g') return 'G • Armador';
    if (pos.contains('forward') || pos == 'f') return 'F • Ala';
    if (pos.contains('center') || pos == 'c') return 'C • Pivô';
    return apiPosition.isNotEmpty ? apiPosition : 'N/A';
  }

  void _showSortMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1012),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _sortOptions.map((option) {
                return RadioListTile<String>(
                  value: option,
                  groupValue: _selectedSort,
                  activeColor: Colors.white,
                  title: Text(
                    option,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedSort = value;
                      });
                    }
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: darkBg,
        elevation: 0,
        title: const Text(
          'Jogadores',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  icon: Icon(Icons.search, color: textGrey, size: 20),
                  hintText: 'Buscar jogador...',
                  hintStyle: TextStyle(color: textGrey, fontSize: 14),
                  border: InputBorder.none,
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close, color: textGrey, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : Icon(Icons.close, color: textGrey, size: 18),
                ),
              ),
            ),
          ),

          // Filtros de posição
          SizedBox(
            height: 52,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              itemBuilder: (context, index) {
                final isSelected = _selectedFilterIndex == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4.0,
                    vertical: 8.0,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilterIndex = index;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? brandOrange
                            : const Color(0xFF1A1D21),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? brandOrange : Colors.white12,
                        ),
                      ),
                      child: Text(
                        _filters[index],
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Divider(color: Colors.white10, height: 1),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Lista de jogadores',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: _showSortMenu,
                  child: Text(
                    'Ordenar por',
                    style: TextStyle(
                      color: brandOrange,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: FutureBuilder<List<Player>>(
              future: _playersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: brandOrange),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Erro ao carregar jogadores',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _playersFuture = fetchAllPlayers();
                            });
                          },
                          icon: Icon(Icons.refresh, color: brandOrange),
                          label: Text(
                            'Tentar novamente',
                            style: TextStyle(color: brandOrange),
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (snapshot.hasData) {
                  List<Player> filteredPlayers = snapshot.data!.where((player) {
                    final matchesPos = _matchesPositionFilter(
                      player.position,
                      _selectedFilterIndex,
                    );
                    final matchesSearch =
                        player.fullName.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ||
                        player.teamName.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        );
                    return matchesPos && matchesSearch;
                  }).toList();

                  filteredPlayers.sort((a, b) {
                    switch (_selectedSort) {
                      case 'Nome (A–Z)':
                        return a.fullName.compareTo(b.fullName);
                      case 'Pontos por jogo (PTS)':
                        return b.avgPoints.compareTo(a.avgPoints);
                      case 'Assistências por jogo (AST)':
                        return b.avgAssists.compareTo(a.avgAssists);
                      case 'Rebotes por jogo (REB)':
                        return b.avgRebounds.compareTo(a.avgRebounds);
                      case 'Mais temporadas registradas':
                        final cmp = b.seasonsCount.compareTo(a.seasonsCount);
                        if (cmp != 0) return cmp;
                        return b.avgPoints.compareTo(a.avgPoints);
                      default:
                        return b.avgPoints.compareTo(a.avgPoints);
                    }
                  });

                  if (filteredPlayers.isEmpty) {
                    return const Center(
                      child: Text(
                        'Nenhum jogador encontrado.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 110.0),
                    itemCount: filteredPlayers.length,
                    itemBuilder: (context, index) {
                      final player = filteredPlayers[index];
                      final initial = player.fullName.isNotEmpty
                          ? player.fullName[0].toUpperCase()
                          : '?';
                      final apiImageUrl =
                          '$_apiBaseUrl/players/${player.id}/image';

                      Widget buildInitialAvatar() {
                        return Center(
                          child: Text(
                            initial,
                            style: TextStyle(
                              color: brandOrange,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        );
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10.0),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 14.0,
                        ),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: InkWell(
                          onTap: () {
                            // Navegar para detalhes do jogador
                          },
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22252A),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: ClipOval(
                                  child: Image.network(
                                    apiImageUrl,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      if (player.imageUrl.isEmpty) {
                                        return buildInitialAvatar();
                                      }
                                      return Image.network(
                                        player.imageUrl,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) => buildInitialAvatar(),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      player.fullName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      player.teamName.isNotEmpty
                                          ? player.teamName
                                          : 'Sem Time',
                                      style: TextStyle(
                                        color: textGrey,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatPositionLine(player.position),
                                      style: TextStyle(
                                        color: textGrey.withOpacity(0.8),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: brandOrange,
                                size: 22,
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
          ),
        ],
      ),
    );
  }
}
