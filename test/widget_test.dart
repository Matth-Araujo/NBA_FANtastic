import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nba_fantastic/Widgets/player_card.dart';

void main() {
  testWidgets('PlayerCard renders player name and stats', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: PlayerCard(
          name: 'LeBron James',
          pts: '26.8 PTS',
          rebAst: '7.5 REB • 7.4 AST',
        ),
      ),
    );

    expect(find.text('LeBron James'), findsOneWidget);
    expect(find.text('26.8 PTS'), findsOneWidget);
    expect(find.text('7.5 REB • 7.4 AST'), findsOneWidget);
  });
}
