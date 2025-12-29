import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last Updated: ${DateTime.now().toString().split(' ')[0]}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            
            _buildSection(
              context,
              '1. Information We Collect',
              'We collect the following types of information:\n\n'
              '**Personal Information:**\n'
              '• Full name, email address, phone number\n'
              '• Namibian ID number (if provided)\n'
              '• Profile photo (optional)\n'
              '• Emergency contact information\n\n'
              '**Location Data:**\n'
              '• GPS coordinates when filing reports\n'
              '• Location during emergency alerts\n'
              '• General location for safety alerts\n\n'
              '**Usage Data:**\n'
              '• App activity and feature usage\n'
              '• Crime reports and their details\n'
              '• Emergency alert history\n'
              '• Notification preferences\n\n'
              '**Device Information:**\n'
              '• Device type and model\n'
              '• Operating system version\n'
              '• App version\n'
              '• Unique device identifiers',
            ),
            
            _buildSection(
              context,
              '2. How We Use Your Information',
              'Your information is used to:\n\n'
              '• **Provide Services:** Process crime reports, send alerts, facilitate emergency responses\n'
              '• **Safety & Security:** Share location and reports with law enforcement\n'
              '• **Communication:** Send safety notifications, status updates, and important alerts\n'
              '• **Improve Services:** Analyze usage patterns to enhance features\n'
              '• **Account Management:** Verify identity, maintain your profile, manage preferences\n'
              '• **Legal Compliance:** Comply with laws and respond to legal requests',
            ),
            
            _buildSection(
              context,
              '3. Information Sharing',
              'We share your information with:\n\n'
              '**Law Enforcement:**\n'
              '• Crime report details and evidence\n'
              '• Emergency alert locations\n'
              '• User information when legally required\n\n'
              '**Emergency Services:**\n'
              '• Your location during active emergencies\n'
              '• Contact information for responders\n'
              '• Emergency contact notifications\n\n'
              '**Service Providers:**\n'
              '• Supabase (database and authentication)\n'
              '• Google Maps (location services)\n'
              '• Cloud storage providers\n\n'
              '**We do NOT:**\n'
              '• Sell your personal information\n'
              '• Share data with advertisers\n'
              '• Provide data to third parties for marketing',
            ),
            
            _buildSection(
              context,
              '4. Data Security',
              'We protect your data using:\n\n'
              '• **Encryption:** Data encrypted in transit (HTTPS) and at rest\n'
              '• **Authentication:** Secure login with Supabase authentication\n'
              '• **Access Controls:** Row-level security policies\n'
              '• **Monitoring:** Regular security audits and monitoring\n'
              '• **Backups:** Automated, secure database backups\n\n'
              'However, no method of transmission or storage is 100% secure. We cannot guarantee absolute security.',
            ),
            
            _buildSection(
              context,
              '5. Your Rights',
              'You have the right to:\n\n'
              '• **Access:** Request a copy of your personal data\n'
              '• **Correction:** Update inaccurate or incomplete information\n'
              '• **Deletion:** Request deletion of your account and data\n'
              '• **Export:** Download your data in a portable format\n'
              '• **Opt-out:** Unsubscribe from non-essential communications\n'
              '• **Object:** Object to processing of your personal data\n\n'
              'To exercise these rights, contact us at privacy@311security.na',
            ),
            
            _buildSection(
              context,
              '6. Location Data',
              'Location data is collected when you:\n\n'
              '• Open the app (for nearby alerts)\n'
              '• File a crime report (exact location)\n'
              '• Trigger an emergency alert (real-time tracking)\n'
              '• View the map (current position)\n\n'
              'You can disable location access in your device settings, but this will limit:\n'
              '• Crime report submission\n'
              '• Emergency alert effectiveness\n'
              '• Nearby safety alerts\n'
              '• Map functionality',
            ),
            
            _buildSection(
              context,
              '7. Crime Reports & Evidence',
              'When you submit a crime report:\n\n'
              '• Report details are stored in our database\n'
              '• Evidence photos are stored in secure cloud storage\n'
              '• Reports are shared with relevant law enforcement agencies\n'
              '• Anonymous reports do not include your name but maintain a link to your account\n'
              '• You can view your report history in the app\n\n'
              'Reports cannot be fully deleted once submitted, as they may be part of active investigations.',
            ),
            
            _buildSection(
              context,
              '8. Data Retention',
              'We retain your data for:\n\n'
              '• **Active Accounts:** Duration of account + 1 year after deletion\n'
              '• **Crime Reports:** 7 years (legal requirement)\n'
              '• **Emergency Alerts:** 3 years\n'
              '• **Safety Alerts:** Until expired or made inactive\n'
              '• **Usage Logs:** 90 days\n\n'
              'Certain data may be retained longer if required by law or for legal proceedings.',
            ),
            
            _buildSection(
              context,
              '9. Children\'s Privacy',
              'Our service is not intended for users under 13 years of age. We do not knowingly collect data from children under 13. If you believe we have collected data from a child under 13, please contact us immediately.',
            ),
            
            _buildSection(
              context,
              '10. International Data Transfers',
              'Your data may be transferred to and processed in countries outside Namibia, including countries that may not have equivalent data protection laws. We ensure appropriate safeguards are in place for such transfers.',
            ),
            
            _buildSection(
              context,
              '11. Cookies & Tracking',
              'We use:\n\n'
              '• **Essential Cookies:** For authentication and app functionality\n'
              '• **Analytics:** To understand app usage and improve performance\n'
              '• **Preferences:** To remember your settings\n\n'
              'We do not use advertising or tracking cookies.',
            ),
            
            _buildSection(
              context,
              '12. Changes to Privacy Policy',
              'We may update this policy from time to time. Significant changes will be communicated via:\n\n'
              '• In-app notification\n'
              '• Email to registered users\n'
              '• Notice on this page\n\n'
              'Continued use after changes constitutes acceptance of the updated policy.',
            ),
            
            _buildSection(
              context,
              '13. Contact Us',
              'For privacy-related questions or to exercise your rights:\n\n'
              'Email: privacy@311security.na\n'
              'Phone: +264 61 311 3110\n'
              'Address: Windhoek, Namibia\n\n'
              'Data Protection Officer: dataprotection@311security.na',
            ),
            
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, color: Colors.green.shade700, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your privacy is important to us. We are committed to protecting your personal information and using it only for the purposes of providing safety and security services.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green.shade900,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

