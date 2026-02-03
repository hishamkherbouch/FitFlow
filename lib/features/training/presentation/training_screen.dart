import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'create_template_screen.dart';
import '../data/workout_template.dart';
import '../data/workout_template_repository.dart';
import 'template_detail_screen.dart';
import 'workout_session_screen.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  final _repository = WorkoutTemplateRepository();
  bool _isLoading = false;
  String? _error;
  List<WorkoutTemplate> _templates = [];

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final templates = await _repository.getTemplates();
      if (mounted) {
        setState(() {
          _templates = templates;
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

  Future<void> _openCreateTemplate() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateTemplateScreen()),
    );
    if (result == true) {
      _loadTemplates();
    }
  }

  Future<void> _openTemplateDetail(WorkoutTemplate template) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TemplateDetailScreen(template: template),
      ),
    );
    if (result == true) {
      _loadTemplates();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: _openCreateTemplate,
              borderRadius: BorderRadius.circular(16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_box_outlined,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                      const Gap(16),
                      Expanded(
                        child: Text(
                          'Create Template',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            ),
            const Gap(16),
            FilledButton.icon(
              onPressed: _startEmptyWorkout,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Empty Workout'),
            ),
            const Gap(24),
            Text(
              'Saved templates',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Gap(8),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              )
            else if (_templates.isEmpty)
              Text(
                'No templates saved yet.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _templates.length,
                  separatorBuilder: (_, __) => const Gap(12),
                  itemBuilder: (context, index) {
                    final template = _templates[index];
                    final exerciseCount = template.exercises.length;
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(template.title),
                              subtitle: Text('$exerciseCount exercises'),
                              trailing: PopupMenuButton<String>(
                                icon: const Icon(Icons.more_horiz),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _openTemplateDetail(template);
                                  } else if (value == 'delete') {
                                    _confirmDeleteTemplate(template);
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit template'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete template'),
                                  ),
                                ],
                              ),
                              onTap: () => _openTemplateDetail(template),
                            ),
                            const Gap(8),
                            OutlinedButton.icon(
                              onPressed: () => _startTemplateWorkout(template),
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Start Routine'),
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

  void _startEmptyWorkout() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const WorkoutSessionScreen(),
      ),
    );
  }

  void _startTemplateWorkout(WorkoutTemplate template) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkoutSessionScreen(
          title: template.title,
          templateExercises: template.exercises,
        ),
      ),
    );
  }

  Future<void> _confirmDeleteTemplate(WorkoutTemplate template) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete template?'),
          content: Text('Delete "${template.title}"?'),
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
    await _repository.deleteTemplate(template.id);
    if (mounted) {
      _loadTemplates();
    }
  }
}
