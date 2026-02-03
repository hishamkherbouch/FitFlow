import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../data/exercise.dart';
import '../data/workout_template.dart';
import '../data/workout_template_repository.dart';

class TemplateDetailScreen extends StatefulWidget {
  const TemplateDetailScreen({super.key, required this.template});

  final WorkoutTemplate template;

  @override
  State<TemplateDetailScreen> createState() => _TemplateDetailScreenState();
}

class _TemplateDetailScreenState extends State<TemplateDetailScreen> {
  final _repository = WorkoutTemplateRepository();
  late String _title;
  late List<TemplateExercise> _exercises;
  bool _isSavingOrder = false;
  bool _isOrderDirty = false;

  @override
  void initState() {
    super.initState();
    _title = widget.template.title;
    _exercises = List.of(widget.template.exercises);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          TextButton(
            onPressed: _isOrderDirty && !_isSavingOrder ? _saveOrder : null,
            child: _isSavingOrder
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save order'),
          ),
          IconButton(
            tooltip: 'Edit title',
            icon: const Icon(Icons.edit),
            onPressed: _editTitle,
          ),
          IconButton(
            tooltip: 'Delete template',
            icon: const Icon(Icons.delete),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Exercises',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Gap(12),
            if (_exercises.isEmpty)
              Text(
                'No exercises saved in this template.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              Expanded(
                child: ReorderableListView.builder(
                  itemCount: _exercises.length,
                  onReorder: _onReorder,
                  buildDefaultDragHandles: false,
                  itemBuilder: (context, index) {
                    final templateExercise = _exercises[index];
                    final exercise = templateExercise.exercise;
                    final restLabel = templateExercise.restSeconds == null
                        ? 'no rest'
                        : _formatDuration(templateExercise.restSeconds!);
                    return ListTile(
                      key: ValueKey(exercise.id),
                      title: Text(exercise.name),
                      subtitle: Text(
                        '${exercise.equipment} • ${exercise.targetMuscle} • '
                        '${templateExercise.sets} sets • $restLabel',
                      ),
                      trailing: ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Icons.drag_handle),
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

  Future<void> _editTitle() async {
    final controller = TextEditingController(text: _title);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit template title'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(controller.text.trim());
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.dispose();
      });
    } else {
      controller.dispose();
    }

    if (result == null || result.isEmpty) {
      return;
    }
    await _repository.updateTemplateTitle(
      templateId: widget.template.id,
      title: result,
    );
    if (mounted) {
      setState(() {
        _title = result;
      });
    }
  }

  Future<void> _confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete template?'),
          content:
              const Text('This will remove the template and its exercises.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }
    await _repository.deleteTemplate(widget.template.id);
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _exercises.removeAt(oldIndex);
      _exercises.insert(newIndex, item);
      _isOrderDirty = true;
    });
  }

  Future<void> _saveOrder() async {
    setState(() {
      _isSavingOrder = true;
    });
    try {
      await _repository.replaceTemplateExercises(
        templateId: widget.template.id,
        exercises: _exercises,
      );
      if (mounted) {
        setState(() {
          _isOrderDirty = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order saved.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingOrder = false;
        });
      }
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainder = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainder.toString().padLeft(2, '0')}';
  }
}
