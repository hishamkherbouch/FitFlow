import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../nutrition/data/nutrition_repository.dart';
import '../../../core/services/ai_coach_service.dart';

class AiCoachScreen extends StatefulWidget {
  const AiCoachScreen({super.key});

  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends State<AiCoachScreen> {
  final _questionController = TextEditingController();
  final _repository = NutritionRepository();
  final _coachService = AiCoachService();

  bool _isLoading = false;
  String? _response;
  String? _error;

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _askCoach() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) {
      setState(() {
        _error = 'Please enter a question.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _response = null;
    });

    try {
      final logs = await _repository.getLogsForLastDays(7);
      final logsJson = jsonEncode(
        logs.map((log) => log.toJson()).toList(),
      );

      final advice = await _coachService.getCoachAdvice(
        logsJson: logsJson,
        question: question,
      );

      setState(() {
        _response = advice;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Coach'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _questionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Ask your coach',
                hintText: 'e.g., "How can I improve my protein intake?"',
                border: OutlineInputBorder(),
              ),
              enabled: !_isLoading,
            ),
            const Gap(12),
            ElevatedButton(
              onPressed: _isLoading ? null : _askCoach,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Ask Coach'),
            ),
            const Gap(16),
            if (_error != null)
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ),
            if (_response != null) ...[
              Text(
                'Coach Response:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Gap(8),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: Text(
                        _response!,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
