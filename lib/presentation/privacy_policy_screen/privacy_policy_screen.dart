import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLastUpdated(),
                    const SizedBox(height: 24),
                    _buildIntroCard(),
                    const SizedBox(height: 20),
                    _buildSection(
                      icon: Icons.info_outline_rounded,
                      title: '1. Information We Collect',
                      content: [
                        _PolicyItem(
                          subtitle: 'Account Information',
                          text:
                              'When you create an account, we collect your email address, display name, and optional profile details such as height, weight, gender, and fitness goals.',
                        ),
                        _PolicyItem(
                          subtitle: 'Health & Fitness Data',
                          text:
                              'We collect workout logs, nutrition entries, sleep records, and activity data that you voluntarily enter into the app. This data is stored securely in your personal account.',
                        ),
                        _PolicyItem(
                          subtitle: 'Device Information',
                          text:
                              'We may collect information about the devices you link to your account, including device name and type, to provide a connected experience.',
                        ),
                        _PolicyItem(
                          subtitle: 'Usage Data',
                          text:
                              'We collect anonymized usage analytics to understand how features are used and to improve the app experience. This data cannot be used to identify you personally.',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      icon: Icons.settings_suggest_outlined,
                      title: '2. How We Use Your Information',
                      content: [
                        _PolicyItem(
                          subtitle: 'Providing the Service',
                          text:
                              'Your data is used to power the core features of FitTrack — tracking workouts, nutrition, sleep, and activity — and to sync your data across devices.',
                        ),
                        _PolicyItem(
                          subtitle: 'Personalization',
                          text:
                              'We use your profile and fitness data to personalize recommendations, workout plans, and insights tailored to your goals.',
                        ),
                        _PolicyItem(
                          subtitle: 'Account Management',
                          text:
                              'Your email address is used for authentication, account recovery, and important service communications.',
                        ),
                        _PolicyItem(
                          subtitle: 'App Improvement',
                          text:
                              'Aggregated, anonymized data helps us identify bugs, improve performance, and develop new features.',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      icon: Icons.share_outlined,
                      title: '3. Data Sharing & Disclosure',
                      content: [
                        _PolicyItem(
                          subtitle: 'We Do Not Sell Your Data',
                          text:
                              'We never sell, rent, or trade your personal information or health data to third parties for marketing or advertising purposes.',
                        ),
                        _PolicyItem(
                          subtitle: 'Service Providers',
                          text:
                              'We use trusted third-party services (such as Supabase for secure cloud storage) that process data on our behalf under strict confidentiality agreements.',
                        ),
                        _PolicyItem(
                          subtitle: 'Legal Requirements',
                          text:
                              'We may disclose your information if required by law, court order, or governmental authority, or to protect the rights and safety of our users.',
                        ),
                        _PolicyItem(
                          subtitle: 'Connected Health Apps',
                          text:
                              'If you choose to connect third-party health apps (e.g., Apple Health, Google Fit), data sharing is governed by those apps\' own privacy policies.',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      icon: Icons.security_outlined,
                      title: '4. Data Security',
                      content: [
                        _PolicyItem(
                          subtitle: 'Encryption',
                          text:
                              'All data is transmitted over HTTPS and stored with industry-standard encryption. Passwords are hashed and never stored in plain text.',
                        ),
                        _PolicyItem(
                          subtitle: 'Access Controls',
                          text:
                              'Row-level security policies ensure that each user can only access their own data. Our infrastructure is protected by multiple layers of security.',
                        ),
                        _PolicyItem(
                          subtitle: 'Breach Notification',
                          text:
                              'In the unlikely event of a data breach affecting your personal information, we will notify you promptly in accordance with applicable laws.',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      icon: Icons.person_outline_rounded,
                      title: '5. Your Rights & Choices',
                      content: [
                        _PolicyItem(
                          subtitle: 'Access & Correction',
                          text:
                              'You can view and update your personal information at any time from the Account screen in the app.',
                        ),
                        _PolicyItem(
                          subtitle: 'Data Portability',
                          text:
                              'You have the right to request a copy of your personal data in a portable format. Contact us at privacy@fittrack.app to make a request.',
                        ),
                        _PolicyItem(
                          subtitle: 'Account Deletion',
                          text:
                              'You can permanently delete your account and all associated data at any time from the Account screen. This action is irreversible and removes all your data from our servers.',
                        ),
                        _PolicyItem(
                          subtitle: 'Opt-Out',
                          text:
                              'You may opt out of non-essential communications at any time by updating your notification preferences in Settings.',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      icon: Icons.child_care_outlined,
                      title: '6. Children\'s Privacy',
                      content: [
                        _PolicyItem(
                          subtitle: 'Age Restriction',
                          text:
                              'FitTrack is not intended for children under the age of 13. We do not knowingly collect personal information from children under 13. If you believe a child has provided us with personal information, please contact us immediately.',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      icon: Icons.update_rounded,
                      title: '7. Changes to This Policy',
                      content: [
                        _PolicyItem(
                          subtitle: 'Policy Updates',
                          text:
                              'We may update this Privacy Policy from time to time. We will notify you of significant changes via email or an in-app notification. Continued use of the app after changes constitutes acceptance of the updated policy.',
                        ),
                        _PolicyItem(
                          subtitle: 'Version History',
                          text:
                              'The "Last Updated" date at the top of this policy reflects when the most recent changes were made.',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      icon: Icons.mail_outline_rounded,
                      title: '8. Contact Us',
                      content: [
                        _PolicyItem(
                          subtitle: 'Privacy Inquiries',
                          text:
                              'If you have any questions, concerns, or requests regarding this Privacy Policy or how we handle your data, please contact our privacy team at:\n\nEmail: privacy@fittrack.app\nAddress: FitTrack Inc., 123 Wellness Ave, San Francisco, CA 94105',
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariantDark,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppTheme.textPrimary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Privacy Policy',
            style: GoogleFonts.manrope(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastUpdated() {
    return Text(
      'Last updated: August 16, 2026',
      style: GoogleFonts.manrope(
        fontSize: 12,
        color: AppTheme.textMuted,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryContainer,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppTheme.primary.withAlpha(60), width: 1),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, color: AppTheme.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your privacy matters to us. This policy explains how FitTrack collects, uses, and protects your personal and health data.',
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: AppTheme.textPrimary,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<_PolicyItem> content,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20.0),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...content.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.subtitle,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.text,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Text(
        '© 2026 FitTrack Inc. All rights reserved.',
        style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.textMuted),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _PolicyItem {
  final String subtitle;
  final String text;
  const _PolicyItem({required this.subtitle, required this.text});
}
