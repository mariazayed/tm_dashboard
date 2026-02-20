import 'package:flutter/material.dart';
import 'package:tm_dashboard/enums/strategy_tag_enum.dart';
import 'package:tm_dashboard/models/strategy_tag_model.dart';
import 'package:tm_dashboard/services/static_data_service.dart';
import 'package:tm_dashboard/services/strategy_service.dart';

import '../../models/strategy_model.dart';

class StrategiesScreen extends StatefulWidget {
  const StrategiesScreen({super.key});

  @override
  State<StrategiesScreen> createState() => _StrategiesScreenState();
}

class _StrategiesScreenState extends State<StrategiesScreen> {
  List<StrategyModel> strategies = [];
  List<StrategyTagModel> availableTags = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchStrategies();
    fetchTags();
  }

  Future<void> fetchStrategies() async {
    try {
      final response = await StrategyService.getAll();
      print(response);

      setState(() {
        strategies = response;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> fetchTags() async {
    try {
      final data = await StaticDataService.getAll();
      availableTags = data.strategyTags;
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Strategies")),
      body: Padding(padding: const EdgeInsets.all(16), child: _buildBody()),
      floatingActionButton: FloatingActionButton(
        onPressed: openAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(child: Text(error!));
    }

    if (strategies.isEmpty) {
      return const Center(child: Text("No strategies yet"));
    }

    return ListView.builder(
      itemCount: strategies.length,
      itemBuilder: (context, index) {
        final strategy = strategies[index];

        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strategy.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(strategy.link),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  children: strategy.tags
                      .map((tag) => Chip(label: Text(tag.enName)))
                      .toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> createStrategy({
    required String name,
    required String link,
    required List<StrategyTagEnum> tags,
  }) async {
    await StrategyService.create([
      {
        "name": name,
        "link": link,
        "tags": tags.map((tagEnum) => tagEnum.value).toList(),
      },
    ]);

    await fetchStrategies();
  }

  void openAddDialog() {
    final nameController = TextEditingController();
    final linkController = TextEditingController();
    List<StrategyTagEnum> selectedTags = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Create Strategy",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      /// Name
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: "Strategy Name",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      /// Link
                      TextField(
                        controller: linkController,
                        decoration: InputDecoration(
                          labelText: "Strategy Link",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        "Tags",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: availableTags.map((tag) {
                          final isSelected = selectedTags.contains(tag.id);

                          return FilterChip(
                            label: Text(tag.enName),
                            selected: isSelected,
                            onSelected: (selected) {
                              setStateDialog(() {
                                if (selected) {
                                  selectedTags.add(tag.id);
                                } else {
                                  selectedTags.remove(tag.id);
                                }
                              });
                            },
                            selectedColor: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 28),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () async {
                              if (nameController.text.isEmpty ||
                                  linkController.text.isEmpty ||
                                  selectedTags.isEmpty) {
                                return;
                              }

                              await createStrategy(
                                name: nameController.text,
                                link: linkController.text,
                                tags: selectedTags,
                              );

                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text("Create"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
