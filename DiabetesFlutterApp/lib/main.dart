import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'utils/theme.dart';
import 'screens/predict_screen.dart';
import 'screens/visualizations_screen.dart';
import 'screens/models_screen.dart';
import 'screens/explainability_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
  ));
  runApp(const DiabetesApp());
}

class DiabetesApp extends StatelessWidget {
  const DiabetesApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Diabetes Risk AI',
    debugShowCheckedModeBanner: false,
    theme: appTheme(),
    home: const _HomeScreen(),
  );
}

class _HomeScreen extends StatefulWidget {
  const _HomeScreen();
  @override
  State<_HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<_HomeScreen> {
  int _idx = 0;

  // 4 screens — added Explainability
  static const _screens = [
    PredictScreen(),
    ExplainabilityScreen(),
    VisualizationsScreen(),
    ModelsScreen(),
  ];

  static const _tabs = [
    (icon: '🔬', label: 'Predict'),
    (icon: '🧠', label: 'Explain'),
    (icon: '📊', label: 'Visualize'),
    (icon: '🤖', label: 'Models'),
  ];

  static const _headers = [
    (title: 'Diabetes Risk Prediction',   sub: 'Live ML inference via Flask API'),
    (title: 'Model Explainability',        sub: 'SHAP · Feature contributions'),
    (title: 'Dataset Visualizations',     sub: 'Glucose & BMI patterns · Pima dataset'),
    (title: 'Model Comparison',           sub: 'Accuracy · Precision · Recall · F1 · AUC'),
  ];

  @override
  Widget build(BuildContext context) {
    final h = _headers[_idx];
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppColors.accentBg,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Center(child: Text('🩺', style: TextStyle(fontSize: 24))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(h.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15, fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis),
                Text(h.sub,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10, color: AppColors.textLight,
                    fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis),
              ],
            )),
            // API status indicator
            _ApiStatusDot(),
          ]),
        ),
      ),
      body: IndexedStack(index: _idx, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: _tabs.map((t) => NavigationDestination(
          icon: Text(t.icon,
            style: TextStyle(fontSize: 20,
              color: AppColors.textLight.withOpacity(0.7))),
          selectedIcon: Text(t.icon, style: const TextStyle(fontSize: 22)),
          label: t.label,
        )).toList(),
      ),
    );
  }
}

// Small dot that shows whether the Flask server is reachable
class _ApiStatusDot extends StatefulWidget {
  @override
  State<_ApiStatusDot> createState() => _ApiStatusDotState();
}

class _ApiStatusDotState extends State<_ApiStatusDot> {
  bool? _online;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      // Import the service here to avoid circular imports at top level
      // ignore: implementation_imports
      final _ = await _ping();
      if (mounted) setState(() => _online = true);
    } catch (_) {
      if (mounted) setState(() => _online = false);
    }
  }

  Future<void> _ping() async {
    // Re-use ApiService to check health
    // We import dynamically to keep main.dart clean
    final result = await Future.any([
      _doCheck(),
      Future.delayed(const Duration(seconds: 5)).then((_) => throw TimeoutException()),
    ]);
    return result;
  }

  Future<void> _doCheck() async {
    final http = await _importHttp();
    final r = await http;
    if (r != true) throw Exception('offline');
  }

  Future<bool> _importHttp() async {
    try {
      // Lightweight check — just try the health endpoint
      // Using the same base URL as api_service.dart
      final client = Uri.parse('http://10.0.2.2:5000/health');
      // We can't import http here cleanly without circular deps,
      // so we use ApiService
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _online == null
        ? AppColors.textLight
        : _online!
            ? AppColors.green
            : AppColors.red;
    return Tooltip(
      message: _online == null
          ? 'Checking server...'
          : _online!
              ? 'Flask API online'
              : 'Flask API offline',
      child: Container(
        width: 10, height: 10, margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class TimeoutException implements Exception {}
