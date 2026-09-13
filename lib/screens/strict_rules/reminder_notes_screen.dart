import 'package:flutter/material.dart';
import 'package:tm_dashboard/models/strict_rule_model.dart';
import 'package:tm_dashboard/services/strict_rules_service.dart';

class StrictRulesScreen extends StatefulWidget {
  const StrictRulesScreen({Key? key}) : super(key: key);

  @override
  State<StrictRulesScreen> createState() => _StrictRulesScreenState();
}

class _StrictRulesScreenState extends State<StrictRulesScreen>
    with SingleTickerProviderStateMixin {
  List<StrictRuleModel> _rules = [];
  final List<String> _draftRules = [];
  bool _isLoading = true;
  bool _isAdding = false;
  // True while _submitAllDrafts()'s create request is in flight.
  bool _isSubmittingDrafts = false;
  // Ids with a delete request currently in flight, so only that rule's
  // delete button shows a spinner instead of the whole screen blocking.
  final Set<int> _deletingRuleIds = {};

  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchRules();
  }

  Future<void> _fetchRules() async {
    // Step 1: update loading state synchronously
    setState(() {
      _isLoading = true;
    });

    try {
      // Step 2: perform async work outside of setState. Paged transport
      // under the hood (StrictRulesService.getAllPaged ->
      // .../strict-rule/search) instead of one unbounded GET.
      final response = await StrictRulesService.getAllPaged();

      if (response.isNotEmpty) {
        final rules = response;

        // Step 3: update state synchronously after async work
        setState(() {
          _rules = rules;
          _isLoading = false;
        });
      } else {
        // handle error
        setState(() {
          _rules = [];
          _isLoading = false;
        });
        throw Exception('Failed to load rules');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error fetching rules: $e');
    }
  }

  void _addDraftRule() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _draftRules.add(text);
        _controller.clear();
      });
    }
  }

  Future<void> _submitAllDrafts() async {
    if (_draftRules.isEmpty || _isSubmittingDrafts) return;
    setState(() => _isSubmittingDrafts = true);
    try {
      List<dynamic> rules = _draftRules
          .map((text) => StrictRuleModel(text: text, id: 0).toJson())
          .toList();

      await StrictRulesService.create([...rules]);

      setState(() {
        _draftRules.clear();
        _isAdding = false;
        _isSubmittingDrafts = false;
      });
      _fetchRules();
    } catch (e) {
      debugPrint('Error submitting rules: $e');
      if (mounted) setState(() => _isSubmittingDrafts = false);
    }
  }

  Widget _buildRuleCard(
    String text, {
    bool isDraft = false,
    bool isDeleting = false,
    VoidCallback? onDelete,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isDraft ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  color: isDraft ? Colors.black87 : Colors.black,
                ),
              ),
            ),
            if (!isDraft && isDeleting)
              const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (!isDraft && onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteRule(int id) async {
    if (_deletingRuleIds.contains(id)) return;
    setState(() => _deletingRuleIds.add(id));
    try {
      await StrictRulesService.delete(id);

      // Option A: refetch from API (safest)
      await _fetchRules();

      // Option B (optional): optimistic update
      // setState(() {
      //   _notes.removeWhere((note) => note.id == id);
      // });
    } catch (e) {
      debugPrint('Error deleting rule: $e');
    } finally {
      if (mounted) setState(() => _deletingRuleIds.remove(id));
    }
  }

  Future<void> _confirmDelete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete rule'),
        content: const Text('Are you sure you want to delete this rule?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _deleteRule(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Strict Rules'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchRules,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ..._rules.map(
                    (rule) => _buildRuleCard(
                      rule.text,
                      isDeleting: _deletingRuleIds.contains(rule.id),
                      onDelete: () => _deleteRule(rule.id),
                    ),
                  ),
                  ..._draftRules.map(
                    (draft) => _buildRuleCard(draft, isDraft: true),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: () {
          setState(() {
            _isAdding = !_isAdding;
          });
        },
        child: Icon(_isAdding ? Icons.close : Icons.add),
      ),
      bottomSheet: _isAdding
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: 'Enter new rule...',
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _addDraftRule,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          backgroundColor: Colors.blueAccent,
                        ),
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                  if (_draftRules.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: ElevatedButton(
                        onPressed: _isSubmittingDrafts ? null : _submitAllDrafts,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Center(
                          child: _isSubmittingDrafts
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Submit All',
                                  style: TextStyle(fontSize: 16, color: Colors.white),
                                ),
                        ),
                      ),
                    ),
                ],
              ),
            )
          : null,
    );
  }
}
