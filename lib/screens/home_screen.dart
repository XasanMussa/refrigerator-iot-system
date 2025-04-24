import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

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

  @override
  void initState() {
    super.initState();
    _loadInitialFanSpeed();
    _initConnectivity();
    _setupConnectivityListener();
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
    super.dispose();
  }

  Future<void> _loadInitialFanSpeed() async {
    final speed = await DatabaseService().getCurrentFanSpeed();
    setState(() {
      _currentFanSpeed = speed.toDouble();
    });
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

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
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
                    Expanded(
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Current Temperature',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Expanded(
                                child: SfRadialGauge(
                                  animationDuration: 1000,
                                  enableLoadingAnimation: true,
                                  axes: <RadialAxis>[
                                    RadialAxis(
                                      minimum: -20,
                                      maximum: 40,
                                      ranges: <GaugeRange>[
                                        GaugeRange(
                                          startValue: -20,
                                          endValue: 0,
                                          color: Colors.blue,
                                          startWidth: 10,
                                          endWidth: 10,
                                        ),
                                        GaugeRange(
                                          startValue: 0,
                                          endValue: 20,
                                          color: Colors.green,
                                          startWidth: 10,
                                          endWidth: 10,
                                        ),
                                        GaugeRange(
                                          startValue: 20,
                                          endValue: 40,
                                          color: Colors.red,
                                          startWidth: 10,
                                          endWidth: 10,
                                        ),
                                      ],
                                      pointers: <GaugePointer>[
                                        NeedlePointer(
                                          value: temperature,
                                          enableAnimation: true,
                                          needleColor:
                                              _getTemperatureColor(temperature),
                                          needleLength: 0.6,
                                          needleStartWidth: 1,
                                          needleEndWidth: 8,
                                          knobStyle: const KnobStyle(
                                            knobRadius: 0.09,
                                            borderWidth: 0.05,
                                            borderColor: Colors.grey,
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
                                                  fontSize: 36,
                                                  fontWeight: FontWeight.bold,
                                                  color: _getTemperatureColor(
                                                      temperature),
                                                ),
                                              ),
                                              Text(
                                                _getTemperatureStatus(
                                                    temperature),
                                                style: const TextStyle(
                                                  fontSize: 16,
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
                                    onChangeEnd: (value) {
                                      DatabaseService()
                                          .updateFanSpeed(value.round());
                                    },
                                  ),
                                ),
                                const Icon(Icons.wind_power, size: 32),
                              ],
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
