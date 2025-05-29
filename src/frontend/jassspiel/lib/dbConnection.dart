import 'dart:async';
import 'package:jassspiel/spieler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'jasskarte.dart';
import 'package:uuid/uuid.dart';
class DbConnection {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://wzhaxvxfhdcrpyiswybf.supabase.co/',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind6aGF4dnhmaGRjcnB5aXN3eWJmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY0NDA1MTEsImV4cCI6MjA2MjAxNjUxMX0.yzYZ4jHfAlq2CgpkN_oAue71LLNzAYzP0ABSj1YbFNs',
    );
  }

  final SupabaseClient client = Supabase.instance.client;

  Future<List<Jasskarte>> getAllCards() async {
    final response = await client
        .from('Jasskarten')
        .select('CID, symbol, cardtype');
    List<Jasskarte> cards = [];
    for (final item in response) {
      final card = Jasskarte.wheninit(
        item['symbol'],
        item['CID'],
        item['cardtype'],
        'assets/${item['symbol']}/${item['symbol']}_${item['cardtype']}.png',
      );
      cards.add(card);
    }
    return cards;
  }

  Future<List<Spieler>> loadPlayers(String gid) async {
    print('Loading players for GID: $gid');
    final response = await client
        .from('usergame')
        .select('User(UID,name)')
        .eq('GID', gid);
    print('Response: $response');
    List<Spieler> players = [];
    for (final item in response) {
      final spieler = Spieler(
        item['User']['UID'], 
        item['User']['name'],
      );
      print('added player: ${spieler.username} with UID: ${spieler.uid}');
      players.add(spieler);
    }
    print('Loaded players: ${players.length}');
    return players;
  }

  void shuffleCards(List<Jasskarte> cards, List<Spieler> players, String gid) async {
    cards.shuffle();
    for (int i = 0; i < players.length; i++) {
      final hand = cards.sublist(i * 9, (i + 1) * 9);
      for (final card in hand) {
        await client.from('cardingames').insert({
          'UID': players[i].uid,
          'CID': card.cid,
          'GID': gid,
        });
      }
    }
  }
  //Halb mit KI halb selber: Bsp Code aus Doku, mache das für UserGame
Future<List<Spieler>> waitForFourPlayers(String gid) {
  final completer = Completer<List<Spieler>>();
  void checkPlayers() async {
    final players = await loadPlayers(gid);
    print('Anzahl Spieler: ${players.length}');
    if (players.length == 4) {
      completer.complete(players);
    }
  }
  checkPlayers();
  final channel = client.channel('public:cardingame');
  channel.onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'cardingames',
    callback: (payload) {
      checkPlayers();
    },
  ).subscribe();
  
  return completer.future;
}

  
}