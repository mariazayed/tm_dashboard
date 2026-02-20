import 'package:flutter/material.dart';
import 'package:tm_dashboard/models/strategy_model.dart';
import 'package:tm_dashboard/services/strategy_service.dart';

import '../../models/asset_model.dart';
import '../../models/trade_model.dart';
import '../../services/asset_service.dart';
import '../../services/trade_service.dart';
import 'add_journal_sheet.dart';
import 'classes/trade_journal.dart';
import 'journal_card.dart';

class TradeJournalScreen extends StatefulWidget {
  const TradeJournalScreen({super.key});

  @override
  State<TradeJournalScreen> createState() => _TradeJournalScreenState();
}

class _TradeJournalScreenState extends State<TradeJournalScreen> {
  List<Asset>? assets;
  List<Strategy>? strategies;
  late Future<List<TradeJournal>> future;

  @override
  void initState() {
    super.initState();

    // Ensure the field is ALWAYS initialized, even if fetchAssets throws synchronously.
    //     futureAssets = () {
    //       try {
    //         return AssetService.fetchAssets();
    //       } catch (e, st) {
    //         return Future<List<Asset>>.error(e, st);
    //       }
    //     }();

    future = _load();
  }

  Future<List<TradeJournal>> _load() async {
    try {
      final trades = await TradeService.getAll();
      assets ??= await AssetService.fetchAssets();
      strategies ??= await StrategyService.getAll();
      return groupTrades(trades);
    } catch (e, st) {
      return Future<List<TradeJournal>>.error(e, st);
    }
  }

  Future<void> _openAddJournal() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => AddJournalSheet(assets: assets!, strategies: strategies!),
    );

    setState(() {
      future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trade Journal'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _openAddJournal),
        ],
      ),
      body: FutureBuilder<List<TradeJournal>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print(snapshot.error);
            return Center(
              child: Text(
                'Failed to load journals:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final journals = snapshot.data!;
          if (journals.isEmpty) {
            return const Center(child: Text('No journals yet'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: journals.length,
            itemBuilder: (_, i) => JournalCard(journal: journals[i]),
          );
        },
      ),
    );
  }

  List<TradeJournal> groupTrades(List<Trade> trades) {
    final map = <String, List<Trade>>{};

    for (final t in trades) {
      final key =
          '${t.entryDateTime.toIso8601String()}_${t.exitDateTime.toIso8601String()}';
      map.putIfAbsent(key, () => []).add(t);
    }

    return map.values.map((group) {
      return TradeJournal(
        entryDateTime: group.first.entryDateTime,
        exitDateTime: group.first.exitDateTime,
        trades: group,
      );
    }).toList();
  }
}
