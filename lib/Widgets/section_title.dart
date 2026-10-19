import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final bool showSeeAll;
  final Color textGrey = const Color(0xFFA0A6B1);

  const SectionTitle({
    super.key,
    required this.title,
    required this.showSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    const Color brandOragen = Color(0xFFFF6B00);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,

      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: brandOragen,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),

        const SizedBox(width: 8),

        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const Spacer(),

        if (showSeeAll)
          Row(
            children: const [
              Text(
                'Ver todos ',
                style: TextStyle(color: brandOragen, fontSize: 14),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Color.fromARGB(255, 113, 111, 110),
                size: 16,
              ),
            ],
          ),
      ],
    );
  }
}
