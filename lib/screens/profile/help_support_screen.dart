import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@gymvibe.com',
      query: 'subject=GymVibe Support Request',
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    }
  }

  Widget _buildFaqItem(String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
      iconColor: AppColors.primary,
      collapsedIconColor: AppColors.textSecondary,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(answer, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppPadding.md),
          children: [
            // Contact Support Card
            Card(
              color: AppColors.surfaceElevated,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppPadding.lg),
                child: Column(
                  children: [
                    const Icon(Icons.support_agent_rounded, size: 48, color: AppColors.primary),
                    const SizedBox(height: AppPadding.md),
                    const Text('How can we help you?', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: AppPadding.sm),
                    const Text('Our support team is available 24/7 to assist you.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    const SizedBox(height: AppPadding.lg),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: _launchEmail,
                        icon: const Icon(Icons.email_outlined, color: Colors.white),
                        label: const Text('Contact Support', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppPadding.xl),
            
            // FAQs
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text('FREQUENTLY ASKED QUESTIONS', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            _buildFaqItem('How do I apply for a job?', 'Navigate to the Job Opportunities tab from the home screen, find a job you like, and click "Apply Now". You can manage your applications in your profile.'),
            _buildFaqItem('How do I upload a PR to the leaderboard?', 'Tap the trophy icon in the navigation bar to visit the Leaderboard. Select a category, enter your weight, and tap submit. A gym owner will verify your record.'),
            _buildFaqItem('I am a Gym Owner, how do I edit my profile?', 'Switch to your Gym Owner dashboard using the toggle in your profile screen, then tap the "View Public Profile" button at the top to edit your gym details.'),
            
            const SizedBox(height: AppPadding.xl),
            
            // Legal Links
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text('LEGAL', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              title: const Text('Terms of Service', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
              trailing: const Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.textSecondary),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening Terms of Service...')));
              },
            ),
            ListTile(
              title: const Text('Privacy Policy', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
              trailing: const Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.textSecondary),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening Privacy Policy...')));
              },
            ),
          ],
        ),
      ),
    );
  }
}
