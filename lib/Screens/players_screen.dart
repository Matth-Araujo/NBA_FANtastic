import 'package:flutter/material.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  final Color darkBg = const Color(0xFF121212);
  final Color cardBg = const Color(0xFF1A1C20);
  final Color brandOrange = const Color(0xFFFF6B00);
  final Color textGrey = const Color(0xFFA0A6B1);

  final List<String> _filters = ['Todos', 'Armadores', 'Alas', 'Pivôs'];

  final List<Map<String, dynamic>> _mockPlayers = [
    {'id': 2544, 'name': 'LeBron James', 'team': 'Lakers', 'pos': 'Ala'},
    {
      'id': 201939,
      'name': 'Stephen Curry',
      'team': 'Warriors',
      'pos': 'Armador',
    },
    {'id': 201142, 'name': 'Kevin Durant', 'team': 'Suns', 'pos': 'Ala'},
    {
      'id': 203507,
      'name': 'Giannis Antetokounmpo',
      'team': 'Bucks',
      'pos': 'Ala-Pivô',
    },
    {'id': 203999, 'name': 'Nikola Jokić', 'team': 'Nuggets', 'pos': 'Pivô'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      //app bar
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

      //body
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
            ),
          ),
        ],
      ),
    );
  }
}
