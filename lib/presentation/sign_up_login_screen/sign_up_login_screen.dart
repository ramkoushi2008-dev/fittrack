import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_image_widget.dart';
import './widgets/auth_card_widget.dart';

class SignUpLoginScreen extends StatefulWidget {
  const SignUpLoginScreen({super.key});

  @override
  State<SignUpLoginScreen> createState() => _SignUpLoginScreenState();
}

class _SignUpLoginScreenState extends State<SignUpLoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _heroController;
  late AnimationController _cardController;
  late Animation<double> _heroFade;
  late Animation<Offset> _cardSlide;
  late Animation<double> _cardFade;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _heroFade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _heroController, curve: Curves.easeOut));
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic),
        );
    _cardFade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _cardController, curve: Curves.easeOut));

    _heroController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _cardController.forward();
    });

    // Listen for auth state changes to handle post-OAuth-redirect on web.
    // When the browser returns from Google OAuth, Supabase fires a signedIn
    // event which we catch here to complete navigation.
    _authSubscription = SupabaseService.instance.client.auth.onAuthStateChange
        .listen((data) async {
          if (!mounted) return;
          final event = data.event;
          if (event == AuthChangeEvent.signedIn) {
            await SupabaseService.instance.ensureUserProfile();
            final onboarded = await SupabaseService.instance
                .hasCompletedOnboarding();
            if (mounted) {
              context.go(
                onboarded
                    ? AppRoutes.homeScreen
                    : AppRoutes.personalizationQuestionnaireScreen,
              );
            }
          }
        });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _heroController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          // Hero background
          FadeTransition(
            opacity: _heroFade,
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: CustomImageWidget(
                imageUrl:
                    'https://images.pexels.com/photos/1552242/pexels-photo-1552242.jpeg',
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                semanticLabel:
                    'Athletic person performing a deadlift in a dark gym with dramatic lighting',
              ),
            ),
          ),
          // Gradient overlay
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x00000000),
                  Color(0x80000000),
                  Color(0xFF141515),
                ],
                stops: [0.0, 0.4, 0.75],
              ),
            ),
          ),
          // Top logo row
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: Color(0xFF1A1A1A),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'FitTrack',
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Auth card
          Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: _cardSlide,
              child: FadeTransition(
                opacity: _cardFade,
                child: isTablet
                    ? Center(
                        child: SizedBox(
                          width: 480,
                          child: AuthCardWidget(
                            onLoginSuccess: ({required onboarded}) {
                              context.go(
                                onboarded
                                    ? AppRoutes.homeScreen
                                    : AppRoutes
                                          .personalizationQuestionnaireScreen,
                              );
                            },
                          ),
                        ),
                      )
                    : AuthCardWidget(
                        onLoginSuccess: ({required onboarded}) {
                          context.go(
                            onboarded
                                ? AppRoutes.homeScreen
                                : AppRoutes.personalizationQuestionnaireScreen,
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
