import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/presentation/auth_screen.dart';
import '../../nutrition/data/nutrition_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _repository = NutritionRepository();
  bool _isLoading = false;
  String? _error;
  double _avgCalories = 0;
  int _streakDays = 0;
  int _workoutsLast7Days = 0;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (!mounted) {
        return;
      }
      setState(() {});
      _loadStats();
    });
  }

  bool get _isSignedIn {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return false;
    }
    final provider = user.appMetadata['provider'];
    if (provider is String && provider == 'anonymous') {
      return false;
    }
    final providers = user.appMetadata['providers'];
    if (providers is List && providers.contains('anonymous')) {
      return false;
    }
    return true;
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final logs = await _repository.getLogsForLastDays(7);
      if (logs.isEmpty) {
        setState(() {
          _avgCalories = 0;
          _streakDays = 0;
          _workoutsLast7Days = 0;
        });
        return;
      }

      final caloriesByDay = <DateTime, double>{};
      for (final log in logs) {
        final day = DateTime(log.loggedAt.year, log.loggedAt.month, log.loggedAt.day);
        caloriesByDay.update(day, (value) => value + log.calories,
            ifAbsent: () => log.calories);
      }

      final totalCalories =
          caloriesByDay.values.fold(0.0, (sum, value) => sum + value);
      final avgCalories =
          caloriesByDay.isEmpty ? 0.0 : totalCalories / caloriesByDay.length;

      final streakDays = _calculateStreak(caloriesByDay.keys);

      setState(() {
        _avgCalories = avgCalories;
        _streakDays = streakDays;
        _workoutsLast7Days = 0; // Placeholder until workouts are implemented
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

  int _calculateStreak(Iterable<DateTime> daysWithLogs) {
    final normalized = daysWithLogs
        .map((day) => DateTime(day.year, day.month, day.day))
        .toSet();
    var streak = 0;
    var cursor = DateTime.now();
    for (;;) {
      final day = DateTime(cursor.year, cursor.month, cursor.day);
      if (!normalized.contains(day)) {
        break;
      }
      streak += 1;
      cursor = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      setState(() {
        _avgCalories = 0;
        _streakDays = 0;
        _workoutsLast7Days = 0;
        _error = null;
      });
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Dashboard',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Gap(12),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              )
            else
              Column(
                children: [
                  _StatTile(
                    label: 'Avg calories (7 days)',
                    value: _avgCalories.toStringAsFixed(0),
                    unit: 'kcal',
                  ),
                  const Gap(12),
                  _StatTile(
                    label: 'Workouts (7 days)',
                    value: _workoutsLast7Days.toString(),
                    unit: 'sessions',
                  ),
                  const Gap(12),
                  _StatTile(
                    label: 'Calorie streak',
                    value: _streakDays.toString(),
                    unit: 'days',
                  ),
                ],
              ),
            const Spacer(),
            ElevatedButton(
              onPressed: _isSignedIn ? _signOut : _openAuth,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isSignedIn ? Theme.of(context).colorScheme.error : null,
                foregroundColor:
                    _isSignedIn ? Theme.of(context).colorScheme.onError : null,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(_isSignedIn ? 'Sign out' : 'Sign in'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAuth() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
    if (mounted) {
      setState(() {});
      _loadStats();
    }
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyLarge),
            Text(
              '$value $unit',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
