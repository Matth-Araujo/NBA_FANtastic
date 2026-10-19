import 'package:flutter/material.dart';

import 'Screens/home_screen.dart';

void main() {
  runApp(NbaFantastic());
}

class NbaFantastic extends StatelessWidget {
  const NbaFantastic({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: NbaFantasticScreen(),
    );
  }
}
