import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../data/nutrition_log.dart';
import '../data/nutrition_repository.dart';

class DailyNutritionScreen extends StatefulWidget {
  const DailyNutritionScreen({super.key});

  @override
  State<DailyNutritionScreen> createState() => _DailyNutritionScreenState();
}

class _DailyNutritionScreenState extends State<DailyNutritionScreen> {
  final _repository = NutritionRepository();
  DateTime _selectedDate = DateTime.now();
  List<NutritionLog> _logs = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _logSubscription;

  @override
  void initState() {
    super.initState();
    _loadLogs();
    _logSubscription = _repository.onLogChanged.listen((_) {
      if (mounted) {
        _loadLogs();
      }
    });
  }

  @override
  void dispose() {
    _logSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final logs = await _repository.getLogsForDay(_selectedDate);
      setState(() {
        _logs = logs;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _previousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
    _loadLogs();
  }

  void _nextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
    _loadLogs();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _loadLogs();
    }
  }

  double get _totalCalories =>
      _logs.fold(0.0, (sum, log) => sum + log.calories);
  double get _totalProtein =>
      _logs.fold(0.0, (sum, log) => sum + log.protein);
  double get _totalCarbs => _logs.fold(0.0, (sum, log) => sum + log.carbs);
  double get _totalFats => _logs.fold(0.0, (sum, log) => sum + log.fats);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMMM d, y');
    final isToday = _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Nutrition'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
            tooltip: 'Select date',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _previousDay,
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _selectDate,
                    child: Text(
                      isToday
                          ? 'Today - ${dateFormat.format(_selectedDate)}'
                          : dateFormat.format(_selectedDate),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: isToday ? null : _nextDay,
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error loading logs',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const Gap(8),
                    Text(_error!),
                    const Gap(16),
                    ElevatedButton(
                      onPressed: _loadLogs,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_logs.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.restaurant_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const Gap(16),
                    Text(
                      'No logs for this day',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Gap(8),
                    Text(
                      'Search and log foods to see them here',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Daily Totals',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Gap(12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _TotalItem(
                                label: 'Calories',
                                value: _totalCalories.toStringAsFixed(0),
                                unit: 'kcal',
                              ),
                              _TotalItem(
                                label: 'Protein',
                                value: _totalProtein.toStringAsFixed(1),
                                unit: 'g',
                              ),
                            ],
                          ),
                          const Gap(8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _TotalItem(
                                label: 'Carbs',
                                value: _totalCarbs.toStringAsFixed(1),
                                unit: 'g',
                              ),
                              _TotalItem(
                                label: 'Fats',
                                value: _totalFats.toStringAsFixed(1),
                                unit: 'g',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _logs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        return Dismissible(
                          key: Key(log.id ?? index.toString()),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Theme.of(context).colorScheme.error,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16),
                            child: Icon(
                              Icons.delete,
                              color: Theme.of(context).colorScheme.onError,
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete log?'),
                                content: Text(
                                    'Remove ${log.foodName} from this day?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    style: TextButton.styleFrom(
                                      foregroundColor:
                                          Theme.of(context).colorScheme.error,
                                    ),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                          },
                          onDismissed: (direction) {
                            _deleteLog(log, confirm: false);
                          },
                          child: ListTile(
                            title: Text(log.foodName),
                            subtitle: Text(
                              '${log.grams.toStringAsFixed(0)}g'
                              '${log.servingLabel != null ? ' • ${log.servingLabel}' : ''}',
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${log.calories.toStringAsFixed(0)} kcal',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                Text(
                                  'P: ${log.protein.toStringAsFixed(1)}g',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                            onTap: () => _editLog(log),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _editLog(NutritionLog log) async {
    final amountController =
        TextEditingController(text: log.grams.toStringAsFixed(0));
    double newAmount = log.grams;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${log.foodName}'),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Amount (grams)',
            border: OutlineInputBorder(),
            suffixText: 'g',
          ),
          onChanged: (value) {
            final parsed = double.tryParse(value);
            if (parsed != null && parsed > 0) {
              newAmount = parsed;
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true && newAmount != log.grams) {
      final ratio = newAmount / log.grams;
      try {
        await _repository.updateNutritionLog(
          id: log.id!,
          grams: newAmount,
          calories: log.calories * ratio,
          protein: log.protein * ratio,
          carbs: log.carbs * ratio,
          fats: log.fats * ratio,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Log updated')),
          );
        }
        _loadLogs();
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Update failed: $error')),
          );
        }
      }
    }
  }

  Future<void> _deleteLog(NutritionLog log, {bool confirm = true}) async {
    bool? confirmed = true;
    if (confirm) {
      confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete log?'),
          content: Text('Remove ${log.foodName} from this day?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    }

    if (confirmed == true) {
      try {
        await _repository.deleteNutritionLog(log.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Log deleted')),
          );
        }
        // Don't reload if called from onDismissed as the item is already gone from view
        if (confirm) _loadLogs();
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: $error')),
          );
        }
        // If deletion fails and we swiped, we should probably reload to show the item again
        if (!confirm) _loadLogs();
      }
    }
  }
}

class _TotalItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _TotalItem({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value $unit',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
