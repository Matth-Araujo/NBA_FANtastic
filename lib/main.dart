import 'package:flutter/material.dart';

void main() {
  runApp(NbaFantastic());
}

class NbaFantastic extends StatelessWidget {
  const NbaFantastic({super.key});

  final Color darkBg = const Color(0xFF0B0D12);
  final Color brandOrange = const Color(0xFFFF6B00);
  final Color textGrey = const Color(0xFFA0A6B1);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: darkBg,
          foregroundColor: brandOrange,
          title: const Text(
            'NBA FANtastic',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
          ),
          leading: IconButton(onPressed: () {}, icon: const Icon(Icons.menu)),
        ),
        backgroundColor: darkBg,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Color(0xFF0B0D12),
            image: DecorationImage(
              image: AssetImage('assets/tabela_baskete.png'),
              fit: BoxFit.cover,
              opacity: 0.25,
            ),
          ),
          child: const SafeArea(child: Column()),
        ),
      ),
    );
  }
}
