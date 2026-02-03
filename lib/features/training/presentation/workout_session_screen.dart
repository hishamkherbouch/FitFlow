import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../data/exercise.dart';
import '../data/exercise_repository.dart';
import '../data/workout_template.dart';

class WorkoutSet {
  WorkoutSet({
    required this.reps,
    required this.weight,
    this.completed = false,
  });

  int reps;
  double weight;
  bool completed;
}

class WorkoutSessionScreen extends StatefulWidget {
  const WorkoutSessionScreen({
    super.key,
    this.title,
    this.initialExercises = const [],
    this.templateExercises = const [],
  });

  final String? title;
  final List<Exercise> initialExercises;
  final List<TemplateExercise> templateExercises;

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  final _repository = ExerciseRepository();
  late List<_SessionExercise> _exercises;
  bool _autoRestEnabled = false;
  int _defaultRestSeconds = 120;
  int _restRemaining = 0;
  String? _restExerciseName;
  Timer? _restTimer;

  @override
  void initState() {
    super.initState();
    _exercises = [
      ...widget.templateExercises.map(
        (templateExercise) => _SessionExercise(
          exercise: templateExercise.exercise,
          restSeconds: templateExercise.restSeconds,
          sets: List.generate(
            templateExercise.sets,
            (_) => WorkoutSet(reps: 0, weight: 0),
          ),
        ),
      ),
      ...widget.initialExercises.map(
        (exercise) => _SessionExercise(
          exercise: exercise,
          restSeconds: null,
          sets: [],
        ),
      ),
    ];
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Workout Session'),
        actions: [
          IconButton(
            tooltip: 'Add exercise',
            onPressed: _openSearchSheet,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_restRemaining > 0)
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.timer),
                      const Gap(12),
                      Expanded(
                        child: Text(
                          'Resting ${_formatDuration(_restRemaining)}'
                          '${_restExerciseName != null ? ' after $_restExerciseName' : ''}',
                        ),
                      ),
                      TextButton(
                        onPressed: _stopRestTimer,
                        child: const Text('Skip'),
                      ),
                    ],
                  ),
                ),
              ),
            const Gap(12),
            Row(
              children: [
                Expanded(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Auto rest timer'),
                    value: _autoRestEnabled,
                    onChanged: (value) {
                      setState(() {
                        _autoRestEnabled = value;
                        if (!value) {
                          _stopRestTimer();
                        }
                      });
                    },
                  ),
                ),
                const Gap(12),
                DropdownButton<int>(
                  value: _defaultRestSeconds,
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _defaultRestSeconds = value;
                    });
                  },
                  items: const [
                    DropdownMenuItem(value: 30, child: Text('30s')),
                    DropdownMenuItem(value: 60, child: Text('60s')),
                    DropdownMenuItem(value: 90, child: Text('90s')),
                    DropdownMenuItem(value: 120, child: Text('120s')),
                  ],
                ),
              ],
            ),
            const Gap(12),
            Text(
              'Exercises',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Gap(12),
            if (_exercises.isEmpty)
              Text(
                'No exercises yet. Tap + to add one.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _exercises.length,
                  separatorBuilder: (_, __) => const Gap(12),
                  itemBuilder: (context, index) {
                    final sessionExercise = _exercises[index];
                    final exercise = sessionExercise.exercise;
                    final sets = sessionExercise.sets;
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        exercise.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      const Gap(4),
                                      Text(
                                        '${exercise.equipment} • ${exercise.targetMuscle}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  tooltip: 'Add set',
                                  onPressed: () => _addSet(sessionExercise),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  tooltip: 'Remove exercise',
                                  onPressed: () {
                                    setState(() {
                                      _exercises.removeAt(index);
                                    });
                                  },
                                ),
                              ],
                            ),
                            const Gap(8),
                            if (sets.isEmpty)
                              Text(
                                'No sets yet.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              )
                            else
                              Column(
                                children: [
                                  for (var i = 0; i < sets.length; i++)
                                    _SetRow(
                                      index: i,
                                      set: sets[i],
                                      onEdit: () =>
                                          _editSet(sessionExercise, i),
                                      onChanged: (completed) {
                                        setState(() {
                                          sets[i].completed = completed;
                                        });
                                        if (completed &&
                                            _autoRestEnabled &&
                                            sessionExercise.restSeconds !=
                                                null) {
                                          _startRestTimer(
                                            exercise.name,
                                            sessionExercise.restSeconds!,
                                          );
                                        }
                                      },
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSearchSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _ExerciseSearchSheet(
          repository: _repository,
          onSelected: (exercise) {
            final exists =
                _exercises.any((item) => item.exercise.id == exercise.id);
            if (!exists) {
              setState(() {
                _exercises.add(
                  _SessionExercise(
                    exercise: exercise,
                    restSeconds: null,
                    sets: [],
                  ),
                );
              });
            }
          },
        );
      },
    );
  }

  Future<void> _addSet(_SessionExercise sessionExercise) async {
    final repsController = TextEditingController();
    final weightController = TextEditingController();
    final result = await showDialog<WorkoutSet>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add set'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: repsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Reps',
                  border: OutlineInputBorder(),
                ),
              ),
              const Gap(12),
              TextField(
                controller: weightController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Weight',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final reps = int.tryParse(repsController.text.trim());
                final weight =
                    double.tryParse(weightController.text.trim());
                if (reps == null || reps <= 0) {
                  Navigator.of(context).pop();
                  return;
                }
                Navigator.of(context).pop(
                  WorkoutSet(reps: reps, weight: weight ?? 0),
                );
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        repsController.dispose();
        weightController.dispose();
      });
    } else {
      repsController.dispose();
      weightController.dispose();
    }

    if (result == null) {
      return;
    }
    setState(() {
      sessionExercise.sets.add(result);
    });
  }

  Future<void> _editSet(_SessionExercise sessionExercise, int index) async {
    final current = sessionExercise.sets[index];
    final repsController =
        TextEditingController(text: current.reps.toString());
    final weightController =
        TextEditingController(text: current.weight.toString());
    final result = await showDialog<WorkoutSet>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit set'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: repsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Reps',
                  border: OutlineInputBorder(),
                ),
              ),
              const Gap(12),
              TextField(
                controller: weightController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Weight',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final reps = int.tryParse(repsController.text.trim()) ?? 0;
                final weight =
                    double.tryParse(weightController.text.trim()) ?? 0;
                Navigator.of(context).pop(
                  WorkoutSet(
                    reps: reps,
                    weight: weight,
                    completed: current.completed,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        repsController.dispose();
        weightController.dispose();
      });
    } else {
      repsController.dispose();
      weightController.dispose();
    }
    if (result == null) {
      return;
    }
    setState(() {
      sessionExercise.sets[index] = result;
    });
  }

  void _startRestTimer(String exerciseName, int restSeconds) {
    _restTimer?.cancel();
    setState(() {
      _restRemaining = restSeconds;
      _restExerciseName = exerciseName;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _restRemaining -= 1;
        if (_restRemaining <= 0) {
          _restRemaining = 0;
          _restExerciseName = null;
          timer.cancel();
        }
      });
    });
  }

  void _stopRestTimer() {
    _restTimer?.cancel();
    setState(() {
      _restRemaining = 0;
      _restExerciseName = null;
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainder = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainder.toString().padLeft(2, '0')}';
  }
}

class _SessionExercise {
  _SessionExercise({
    required this.exercise,
    required this.sets,
    required this.restSeconds,
  });

  final Exercise exercise;
  final List<WorkoutSet> sets;
  final int? restSeconds;
}

class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.index,
    required this.set,
    required this.onEdit,
    required this.onChanged,
  });

  final int index;
  final WorkoutSet set;
  final VoidCallback onEdit;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 36,
          child: Text('Set ${index + 1}'),
        ),
        Expanded(
          child: Text('${set.reps} reps'),
        ),
        Expanded(
          child: Text('${set.weight.toStringAsFixed(1)} lb'),
        ),
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: onEdit,
        ),
        Checkbox(
          value: set.completed,
          onChanged: (value) => onChanged(value ?? false),
        ),
      ],
    );
  }
}

class _ExerciseSearchSheet extends StatefulWidget {
  const _ExerciseSearchSheet({
    required this.repository,
    required this.onSelected,
  });

  final ExerciseRepository repository;
  final ValueChanged<Exercise> onSelected;

  @override
  State<_ExerciseSearchSheet> createState() => _ExerciseSearchSheetState();
}

class _ExerciseSearchSheetState extends State<_ExerciseSearchSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;
  bool _isLoading = false;
  String? _error;
  List<Exercise> _results = [];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Search exercises',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _onQueryChanged,
            ),
            const Gap(12),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(),
              )
            else if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              )
            else if (_controller.text.trim().isEmpty)
              Text(
                'Type to search the database.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else if (_results.isEmpty)
              Text(
                'No exercises found.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final exercise = _results[index];
                    return ListTile(
                      title: Text(exercise.name),
                      subtitle: Text(
                        '${exercise.equipment} • ${exercise.targetMuscle}',
                      ),
                      trailing: const Icon(Icons.add),
                      onTap: () {
                        widget.onSelected(exercise);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _search);
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _error = null;
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await widget.repository.searchExercises(query);
      if (mounted) {
        setState(() {
          _results = results;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
