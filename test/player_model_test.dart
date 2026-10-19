import 'package:flutter_test/flutter_test.dart';
import 'package:nba_fantastic/player_model.dart';

void main() {
  group('Player Model Tests', () {
    test('fromJson parses API response correctly', () {
      final json = {
        '_id': 2544,
        'full_name': 'LeBron James',
        'position': 'Forward',
        'career': {
          'avg': {
            'points': 26.8,
            'rebounds': 7.5,
            'assists': 7.4,
          }
        },
        'team': {
          'abbreviation': 'PHI',
          'name': 'Philadelphia 76ers',
        }
      };

      final player = Player.fromJson(json);

      expect(player.id, 2544);
      expect(player.fullName, 'LeBron James');
      expect(player.firstName, 'LeBron');
      expect(player.lastName, 'James');
      expect(player.position, 'Forward');
      expect(player.teamAbbreviation, 'PHI');
      expect(player.avgPoints, 26.8);
      expect(player.avgRebounds, 7.5);
      expect(player.avgAssists, 7.4);
      expect(player.imageUrl, 'https://cdn.nba.com/headshots/nba/latest/260x190/2544.png');
    });

    test('fromJson handles null and missing fields gracefully', () {
      final json = <String, dynamic>{};

      final player = Player.fromJson(json);

      expect(player.id, 0);
      expect(player.fullName, 'Desconhecido');
      expect(player.avgPoints, 0.0);
      expect(player.avgRebounds, 0.0);
      expect(player.avgAssists, 0.0);
    });
  });
}
