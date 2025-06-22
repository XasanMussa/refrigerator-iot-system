import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _currentFanSpeed = 0;
  bool _isOnline = false;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  final Connectivity _connectivity = Connectivity();
  DateTime? _startTime;
  DateTime? _finishTime;
  final String _scheduleDocId = '6cAYLqlSMoFWvERuwOQh';
  bool _isSavingSchedule = false;
  Timer? _scheduleCheckTimer;
  bool _isScheduledTime = false;

  @override
  void initState() {
    super.initState();
    _loadInitialFanSpeed();
    _initConnectivity();
    _setupConnectivityListener();
    _loadSchedule();
    _startScheduleChecker();
  }

  void _startScheduleChecker() {
    // Check every minute
    _scheduleCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkScheduleTime();
    });
    // Initial check
    _checkScheduleTime();
  }

  Future<void> _checkScheduleTime() async {
    if (_startTime == null || _finishTime == null) return;

    final now = DateTime.now();
    final isWithinSchedule =
        now.isAfter(_startTime!) && now.isBefore(_finishTime!);

    if (isWithinSchedule && !_isScheduledTime) {
      // Within schedule time - set fan speed to 200
      await DatabaseService().updateFanSpeed(200);
      setState(() {
        _isScheduledTime = true;
        _currentFanSpeed = 200;
      });
    } else if (!isWithinSchedule && _isScheduledTime) {
      // Outside schedule time - don't modify fan speed
      setState(() {
        _isScheduledTime = false;
      });
    }
  }

  Future<void> _cancelSchedule() async {
    setState(() {
      _isSavingSchedule = true;
    });

    try {
      await DatabaseService().cancelSchedule(_scheduleDocId);
      setState(() {
        _startTime = null;
        _finishTime = null;
        _isScheduledTime = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schedule cancelled successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel schedule: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingSchedule = false;
        });
      }
    }
  }

  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      if (mounted) {
        setState(() {
          _isOnline = result == ConnectivityResult.wifi ||
              result == ConnectivityResult.mobile ||
              result == ConnectivityResult.ethernet;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isOnline = false;
        });
      }
    }
  }

  void _setupConnectivityListener() {
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      if (mounted) {
        setState(() {
          _isOnline = result == ConnectivityResult.wifi ||
              result == ConnectivityResult.mobile ||
              result == ConnectivityResult.ethernet;
        });
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _scheduleCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialFanSpeed() async {
    final speed = await DatabaseService().getCurrentFanSpeed();
    setState(() {
      _currentFanSpeed = speed.toDouble();
    });
  }

  Future<void> _loadSchedule() async {
    try {
      final schedule = await DatabaseService().getSchedule(_scheduleDocId);
      if (schedule != null) {
        setState(() {
          _startTime = schedule['startTime']?.toDate();
          _finishTime = schedule['finishTime']?.toDate();
        });
        _checkScheduleTime();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load schedule: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _saveSchedule() async {
    if (_startTime == null || _finishTime == null) return;

    setState(() {
      _isSavingSchedule = true;
    });

    try {
      await DatabaseService().updateSchedule(
        _scheduleDocId,
        _startTime!,
        _finishTime!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schedule saved successfully')),
        );
      }
      _checkScheduleTime();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save schedule: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingSchedule = false;
        });
      }
    }
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_startTime ?? DateTime.now()),
      );
      if (time != null) {
        setState(() {
          _startTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _selectFinishTime(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _finishTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_finishTime ?? DateTime.now()),
      );
      if (time != null) {
        setState(() {
          _finishTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _handleFanSpeedChange(double value) async {
    // Only allow manual changes when not in scheduled time
    if (!_isScheduledTime) {
      setState(() {
        _currentFanSpeed = value;
      });
      await DatabaseService().updateFanSpeed(value.round());
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await AuthService().signOut();
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: StreamBuilder<double>(
        stream: DatabaseService().streamTemperature(),
        builder: (context, snapshot) {
          final temperature = snapshot.data ?? 0.0;

          return SingleChildScrollView(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _isOnline ? Icons.wifi : Icons.wifi_off,
                                  color: _isOnline ? Colors.green : Colors.red,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Connection Status',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _isOnline ? Colors.green : Colors.red,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _isOnline ? 'Online' : 'Offline',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text(
                              'Current Temperature',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 200, // Fixed height for better proportion
                              child: SfRadialGauge(
                                animationDuration: 1000,
                                enableLoadingAnimation: true,
                                axes: <RadialAxis>[
                                  RadialAxis(
                                    minimum: -20,
                                    maximum: 40,
                                    showLabels: false,
                                    showTicks: false,
                                    radiusFactor: 0.9,
                                    ranges: <GaugeRange>[
                                      GaugeRange(
                                        startValue: -20,
                                        endValue: 0,
                                        color: Colors.blue,
                                        startWidth: 16,
                                        endWidth: 16,
                                      ),
                                      GaugeRange(
                                        startValue: 0,
                                        endValue: 20,
                                        color: Colors.green,
                                        startWidth: 16,
                                        endWidth: 16,
                                      ),
                                      GaugeRange(
                                        startValue: 20,
                                        endValue: 40,
                                        color: Colors.red,
                                        startWidth: 16,
                                        endWidth: 16,
                                      ),
                                    ],
                                    pointers: <GaugePointer>[
                                      NeedlePointer(
                                        value: temperature,
                                        enableAnimation: true,
                                        needleColor:
                                            _getTemperatureColor(temperature),
                                        needleLength: 0.7,
                                        needleStartWidth: 1,
                                        needleEndWidth: 10,
                                        knobStyle: const KnobStyle(
                                          knobRadius: 0.1,
                                          borderWidth: 0.05,
                                          borderColor: Colors.grey,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                    annotations: <GaugeAnnotation>[
                                      GaugeAnnotation(
                                        widget: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '${temperature.toStringAsFixed(1)}°C',
                                              style: TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.bold,
                                                color: _getTemperatureColor(
                                                    temperature),
                                              ),
                                            ),
                                            Text(
                                              _getTemperatureStatus(
                                                  temperature),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        angle: 90,
                                        positionFactor: 0.5,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Fan Speed',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${_currentFanSpeed.round()}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Icon(Icons.wind_power, size: 24),
                                Expanded(
                                  child: Slider(
                                    value: _currentFanSpeed,
                                    min: 0,
                                    max: 255,
                                    divisions: 255,
                                    label: _currentFanSpeed.round().toString(),
                                    onChanged: (value) {
                                      setState(() {
                                        _currentFanSpeed = value;
                                      });
                                    },
                                    onChangeEnd: _handleFanSpeedChange,
                                  ),
                                ),
                                const Icon(Icons.wind_power, size: 32),
                              ],
                            ),
                            if (_isScheduledTime)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Fan speed is controlled by schedule',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Schedule',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_startTime != null || _finishTime != null)
                                  TextButton(
                                    onPressed: _cancelSchedule,
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Icon(Icons.timer, size: 24),
                                const SizedBox(width: 8),
                                const Text('Start:'),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () => _selectStartTime(context),
                                  child: Text(
                                    _startTime != null
                                        ? DateFormat('MMM dd, yyyy - HH:mm')
                                            .format(_startTime!)
                                        : 'Select Start Time',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.timer_off, size: 24),
                                const SizedBox(width: 8),
                                const Text('Finish:'),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () => _selectFinishTime(context),
                                  child: Text(
                                    _finishTime != null
                                        ? DateFormat('MMM dd, yyyy - HH:mm')
                                            .format(_finishTime!)
                                        : 'Select Finish Time',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: (_startTime != null &&
                                        _finishTime != null &&
                                        !_isSavingSchedule)
                                    ? _saveSchedule
                                    : null,
                                child: _isSavingSchedule
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Save Schedule'),
                              ),
                            ),
                            if (_isScheduledTime)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Fan is currently running on schedule',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getTemperatureColor(double temperature) {
    if (temperature < 0) {
      return Colors.blue;
    } else if (temperature < 20) {
      return Colors.green;
    } else {
      return Colors.red;
    }
  }

  String _getTemperatureStatus(double temperature) {
    if (temperature < 0) {
      return 'Too Cold';
    } else if (temperature < 4) {
      return 'Cold';
    } else if (temperature < 8) {
      return 'Optimal';
    } else if (temperature < 20) {
      return 'Warm';
    } else {
      return 'Too Hot';
    }
  }
}
