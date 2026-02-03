import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../data/exercise.dart';
import '../data/exercise_repository.dart';
import '../data/workout_template.dart';
import '../data/workout_template_repository.dart';

class CreateTemplateScreen extends StatefulWidget {
  const CreateTemplateScreen({super.key});

  @override
  State<CreateTemplateScreen> createState() => _CreateTemplateScreenState();
}

class _CreateTemplateScreenState extends State<CreateTemplateScreen> {
  final _titleController = TextEditingController();
  final _searchController = TextEditingController();
  final _repository = ExerciseRepository();
  final _templateRepository = WorkoutTemplateRepository();

  final List<TemplateExercise> _selectedExercises = [];
  List<Exercise> _searchResults = [];
  Timer? _searchDebounce;
  bool _isSearching = false;
  bool _isSaving = false;
  String? _searchError;

  @override
  void dispose() {
    _titleController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Template'),
        actions: [
          TextButton(
            onPressed: _canSave ? _saveTemplate : null,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
          IconButton(
            tooltip: 'Create exercise',
            onPressed: _openCreateExercise,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Template title',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
            ),
            const Gap(20),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search exercises',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _onSearchChanged(),
            ),
            const Gap(12),
            Expanded(
              child: ListView(
                children: [
                  Text(
                    'Results',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Gap(8),
                  if (_isSearching)
                    const Center(child: CircularProgressIndicator())
                  else if (_searchError != null)
                    Text(
                      _searchError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    )
                  else if (_searchController.text.trim().isEmpty)
                    Text(
                      'Start typing to search the exercise database.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                  else if (_searchResults.isEmpty)
                    Text(
                      'No exercises found.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                  else
                    ..._searchResults.map((exercise) {
                      final isSelected = _selectedExercises
                          .any((item) => item.exercise.id == exercise.id);
                      return Column(
                        children: [
                          ListTile(
                            title: Text(exercise.name),
                            subtitle: Text(
                              '${exercise.equipment} • ${exercise.targetMuscle}',
                            ),
                            trailing: IconButton(
                              tooltip:
                                  isSelected ? 'Already added' : 'Add exercise',
                              icon: Icon(
                                isSelected ? Icons.check : Icons.add,
                              ),
                              onPressed: isSelected
                                  ? null
                                  : () => _addExercise(exercise),
                            ),
                          ),
                          const Divider(height: 1),
                        ],
                      );
                    }),
                  const Gap(16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Selected',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${_selectedExercises.length} added',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const Gap(8),
                  if (_selectedExercises.isEmpty)
                    Text(
                'No exercises added yet.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                  else
                    ..._selectedExercises.map((templateExercise) {
                      final exercise = templateExercise.exercise;
                      return Column(
                        children: [
                          ListTile(
                            title: Text(exercise.name),
                            subtitle: Text(
                              '${exercise.equipment} • ${exercise.targetMuscle}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _selectedExercises.removeWhere(
                                    (item) => item.exercise.id == exercise.id,
                                  );
                                });
                              },
                            ),
                          ),
                          const Gap(8),
                          Row(
                            children: [
                              Expanded(
                                child: _SetsControl(
                                  value: templateExercise.sets,
                                  onChanged: (value) {
                                    setState(() {
                                      final index = _selectedExercises
                                          .indexOf(templateExercise);
                                      _selectedExercises[index] = TemplateExercise(
                                        exercise: templateExercise.exercise,
                                        sets: value,
                                        restSeconds: templateExercise.restSeconds,
                                      );
                                    });
                                  },
                                ),
                              ),
                              const Gap(12),
                              Expanded(
                                child: _RestControl(
                                  restSeconds: templateExercise.restSeconds,
                                  onChanged: (value) {
                                    setState(() {
                                      final index = _selectedExercises
                                          .indexOf(templateExercise);
                                      _selectedExercises[index] = TemplateExercise(
                                        exercise: templateExercise.exercise,
                                        sets: templateExercise.sets,
                                        restSeconds: value,
                                      );
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const Gap(8),
                          const Divider(height: 1),
                        ],
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCreateExercise() async {
    final nameController = TextEditingController();
    final equipmentController = TextEditingController();
    final targetController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create exercise'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Exercise name',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const Gap(12),
              TextField(
                controller: equipmentController,
                decoration: const InputDecoration(
                  labelText: 'Equipment',
                  border: OutlineInputBorder(),
                ),
              ),
              const Gap(12),
              TextField(
                controller: targetController,
                decoration: const InputDecoration(
                  labelText: 'Target muscle',
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
              onPressed: () async {
                final name = nameController.text.trim();
                final equipment = equipmentController.text.trim();
                final target = targetController.text.trim();
                if (name.isEmpty || equipment.isEmpty || target.isEmpty) {
                  Navigator.of(context).pop();
                  _setSearchError('Please fill out all fields.');
                  return;
                }
                try {
                  final created = await _repository.createExercise(
                    name: name,
                    equipment: equipment,
                    targetMuscle: target,
                  );
                  _addExercise(created);
                  final query = _searchController.text.trim().toLowerCase();
                  if (query.isNotEmpty &&
                      created.name.toLowerCase().contains(query)) {
                    setState(() {
                      _searchResults = [
                        created,
                        ..._searchResults.where((item) => item.id != created.id),
                      ];
                    });
                  }
                } catch (error) {
                  _setSearchError(error.toString());
                }
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    nameController.dispose();
    equipmentController.dispose();
    targetController.dispose();
  }

  void _addExercise(Exercise exercise) {
    if (_selectedExercises.any((item) => item.exercise.id == exercise.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${exercise.name} is already in this template.'),
        ),
      );
      return;
    }
    setState(() {
      _selectedExercises.add(
        TemplateExercise(
          exercise: exercise,
          sets: 3,
          restSeconds: null,
        ),
      );
    });
  }

  bool get _canSave {
    return _titleController.text.trim().isNotEmpty &&
        _selectedExercises.isNotEmpty &&
        !_isSaving;
  }

  Future<void> _saveTemplate() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _selectedExercises.isEmpty) {
      _setSearchError('Add a title and at least one exercise.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _templateRepository.createTemplate(
        title: title,
        exercises: List.from(_selectedExercises),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template saved.')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      _setSearchError(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), _performSearch);
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _searchError = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    try {
      final results = await _repository.searchExercises(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
        });
      }
    } catch (error) {
      _setSearchError(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _setSearchError(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _searchError = message;
      _isSearching = false;
    });
  }
}

class _SetsControl extends StatelessWidget {
  const _SetsControl({
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Sets'),
        const Gap(8),
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
        ),
        Text(value.toString()),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => onChanged(value + 1),
        ),
      ],
    );
  }
}

class _RestControl extends StatelessWidget {
  const _RestControl({
    required this.restSeconds,
    required this.onChanged,
  });

  final int? restSeconds;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final label = restSeconds == null
        ? 'No rest'
        : restSeconds == 120
            ? 'Default 2:00'
            : 'Custom ${_format(restSeconds!)}';

    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'none') {
          onChanged(null);
        } else if (value == 'default') {
          onChanged(120);
        } else if (value == 'custom') {
          final seconds = await _pickCustomSeconds(context);
          if (seconds != null) {
            onChanged(seconds);
          }
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'none', child: Text('No rest')),
        PopupMenuItem(value: 'default', child: Text('Default 2:00')),
        PopupMenuItem(value: 'custom', child: Text('Custom...')),
      ],
      child: Row(
        children: [
          const Icon(Icons.timer, size: 18),
          const Gap(6),
          Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }

  static String _format(int seconds) {
    final minutes = seconds ~/ 60;
    final remainder = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainder.toString().padLeft(2, '0')}';
  }

  Future<int?> _pickCustomSeconds(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Custom rest (seconds)'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Seconds',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final seconds = int.tryParse(controller.text.trim());
                Navigator.of(context).pop(seconds);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (context.mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.dispose();
      });
    } else {
      controller.dispose();
    }
    if (result == null || result <= 0) {
      return null;
    }
    return result;
  }
}
