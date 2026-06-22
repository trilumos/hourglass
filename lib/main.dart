import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/billing_providers.dart';
import 'app/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Needed for the session foreground service to message its isolate.
  FlutterForegroundTask.initCommunicationPort();
  // Portrait only — the layouts are designed for portrait; landscape breaks them.
  await SystemChrome.setPreferredOrientations(
    const [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
  );
  final prefs = await SharedPreferences.getInstance();
  // Billing: key-less today (everyone Free); init is guarded and never throws.
  final billing = createBillingService();
  await billing.init();
  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        billingServiceProvider.overrideWithValue(billing),
      ],
      child: const HourglassApp(),
    ),
  );
}
