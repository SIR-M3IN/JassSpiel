import 'package:flutter_test/flutter_test.dart';
import 'package:jassspiel/swaggerConnection.dart';
import 'package:jassspiel/jasskarte.dart';
import 'package:jassspiel/spieler.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

void main() {
  group('SwaggerConnection', () {
    late SwaggerConnection conn;
    const baseUrl = 'http://localhost:8080';

    setUp(() {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/users/testuid' && request.method == 'PUT') {
          return http.Response('', 200);
        }
        if (request.url.path == '/games' && request.method == 'POST') {
          return http.Response(jsonEncode({'gid': 'game123'}), 201);
        }
        if (request.url.path == '/games/game123/join' && request.method == 'POST') {
          return http.Response('', 200);
        }
        if (request.url.path == '/games/game404/join' && request.method == 'POST') {
          return http.Response('', 404);
        }
        if (request.url.path == '/games/game123/players' && request.method == 'GET') {
          return http.Response(jsonEncode([
            {'uid': 'u1', 'name': 'A', 'playernumber': 1},
            {'uid': 'u2', 'name': 'B', 'playernumber': 2}
          ]), 200);
        }
        if (request.url.path == '/cards' && request.method == 'GET') {
          return http.Response(jsonEncode([
            {'symbol': 'Herz', 'cid': 'c1', 'cardtype': 'Ass', 'path': 'p1'}
          ]), 200);
        }
        return http.Response('Not found', 404);
      });
      conn = SwaggerConnection(baseUrl: baseUrl, client: mockClient);
    });

    test('upsertUser success', () async {
      await conn.upsertUser('testuid', 'Test');
    });

    test('createGame returns gid', () async {
      final gid = await conn.createGame();
      expect(gid, 'game123');
    });

    test('joinGame returns true for 200', () async {
      final joined = await conn.joinGame('game123');
      expect(joined, isTrue);
    });

    test('joinGame returns false for 404', () async {
      final joined = await conn.joinGame('game404');
      expect(joined, isFalse);
    });

    test('loadPlayers returns Spieler list', () async {
      final players = await conn.loadPlayers('game123');
      expect(players.length, 2);
      expect(players[0].uid, 'u1');
      expect(players[1].username, 'B');
    });

    test('getAllCards returns Jasskarte list', () async {
      final cards = await conn.getAllCards();
      expect(cards.length, 1);
      expect(cards[0].symbol, 'Herz');
      expect(cards[0].cid, 'c1');
    });
  });
}
