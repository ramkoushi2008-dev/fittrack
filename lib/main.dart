import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_export.dart';
import '../widgets/custom_error_widget.dart';
import './routes/app_routes.dart';
import './services/supabase_service.dart';
import './services/theme_controller.dart';
import './theme/app_theme.dart';
import './widgets/custom_error_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('Failed to initialize Supabase: $e');
  }

  // Load the saved light/dark preference before first paint.
  await ThemeController.instance.load();

  bool hasShownError = false;

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!hasShownError) {
      hasShownError = true;

      // Reset flag after 3 seconds to allow error widget on new screens
      Future.delayed(Duration(seconds: 5), () {
        hasShownError = false;
      });

      return CustomErrorWidget(errorDetails: details);
    }
    return SizedBox.shrink();
  };

  // Must be set before runApp so imperative navigation is reflected in the URL
  GoRouter.optionURLReflectsImperativeAPIs = true;

  // 🚨 CRITICAL: Device orientation lock - web does not support orientation lock
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, screenType) {
        return ListenableBuilder(
          listenable: ThemeController.instance,
          builder: (context, _) {
            return MaterialApp.router(
              title: 'FitTrack',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: ThemeController.instance.themeMode,
              // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(1.0)),
                  child: child!,
                );
              },
              // 🚨 END CRITICAL SECTION
              debugShowCheckedModeBanner: false,
              routerConfig: appRouter,
            );
          },
        );
      },
    );
  }
}
