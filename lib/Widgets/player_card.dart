import 'package:flutter/material.dart';

class PlayerCard extends StatelessWidget {
  final String name;
  final String pts;
  final String rebAst;
  final String imageUrl;

  const PlayerCard({
    super.key,
    required this.name,
    required this.pts,
    required this.rebAst,
    this.imageUrl = '',
  });

  @override
  Widget build(BuildContext context) {
    const Color cardBg = Color(0xFF1A1C20);
    const Color textGrey = Color(0xFFA0A6B1);

    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B00),
            offset: Offset(-2, 2),
            blurRadius: 0,
            spreadRadius: 0,
          ),
        ],
        image: const DecorationImage(
          image: AssetImage('assets/fundo_card.jpeg'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: SizedBox(
              height: 60,
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.person,
                          color: Colors.white24,
                          size: 60,
                        );
                      },
                    )
                  : const Icon(Icons.person, color: Colors.white24, size: 60),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            pts,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            rebAst,
            textAlign: TextAlign.center,
            style: const TextStyle(color: textGrey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
