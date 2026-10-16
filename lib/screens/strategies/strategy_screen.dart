import 'package:flutter/material.dart';

import 'package:tm_dashboard/widgets/page_back_button.dart';
import 'package:tm_dashboard/enums/strategy_tag_enum.dart';
import 'package:tm_dashboard/models/strategy_tag_model.dart';
import 'package:tm_dashboard/services/static_data_service.dart';
import 'package:tm_dashboard/services/strategy_service.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/strategy_model.dart';
import '../../theme/app_theme.dart';

class StrategiesScreen extends StatefulWidget {
  const StrategiesScreen({super.key});

  @override
  State<StrategiesScreen> createState() => _StrategiesScreenState();
}

class _StrategiesScreenState extends State<StrategiesScreen> {
  List<Strategy> strategies = [];
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
      // Paged transport under the hood (StrategyService.getAllPaged ->
      // .../strategy/search) instead of one unbounded GET -- see
      // paginated_response.dart's fetchAllPages doc comment.
      final response = await StrategyService.getAllPaged();

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
      appBar: AppBar(
        leading: const PageBackButton(),
        automaticallyImplyLeading: false,
        title: const Text("Strategies"),
      ),
      body: Padding(padding: const EdgeInsets.all(16), child: _buildBody()),
      floatingActionButton: FloatingActionButton(
        onPressed: openAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    final colorScheme = Theme.of(context).colorScheme;

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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: strategies.length,
      itemBuilder: (context, index) {
        final strategy = strategies[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 18),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER ROW
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      strategy.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              /// LINK (Styled)
              _buildLink(strategy.link),

              const SizedBox(height: 16),

              /// TAGS SECTION
              if (strategy.tags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: strategy.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: colorScheme.outline,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        tag.enName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
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
    // Declared outside the StatefulBuilder so it survives its rebuilds --
    // true while createStrategy()'s POST is in flight.
    bool isSubmitting = false;

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
                            onPressed: isSubmitting
                                ? null
                                : () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    if (nameController.text.isEmpty ||
                                        linkController.text.isEmpty ||
                                        selectedTags.isEmpty) {
                                      return;
                                    }

                                    setStateDialog(() => isSubmitting = true);
                                    try {
                                      await createStrategy(
                                        name: nameController.text,
                                        link: linkController.text,
                                        tags: selectedTags,
                                      );
                                      if (context.mounted)
                                        Navigator.pop(context);
                                    } catch (e) {
                                      setStateDialog(
                                        () => isSubmitting = false,
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Failed to create strategy: $e',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text("Create"),
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

  Widget _buildLink(String link) {
    final Uri uri = Uri.parse(link);
    final info = context.semanticColors.info;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: info.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.link_rounded, size: 16, color: info),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                link,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: info,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.open_in_new_rounded, size: 14, color: info),
          ],
        ),
      ),
    );
  }
}
