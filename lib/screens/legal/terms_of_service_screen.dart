import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms of Service',
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
              '1. Acceptance of Terms',
              'By accessing and using the 3:11 Security application ("the App"), you accept and agree to be bound by the terms and provisions of this agreement. If you do not agree to these terms, please do not use the App.',
            ),
            
            _buildSection(
              context,
              '2. Use License',
              'Permission is granted to use the App for personal, non-commercial use to report crimes, access safety alerts, and utilize emergency services. This license does not include:\n\n'
              '• Modifying or copying the App materials\n'
              '• Using the materials for any commercial purpose\n'
              '• Attempting to reverse engineer any software\n'
              '• Removing any copyright or proprietary notations',
            ),
            
            _buildSection(
              context,
              '3. User Responsibilities',
              'You are responsible for:\n\n'
              '• Providing accurate and truthful information\n'
              '• Not submitting false crime reports or emergency alerts\n'
              '• Using emergency features responsibly and only when needed\n'
              '• Maintaining the confidentiality of your account credentials\n'
              '• Respecting the privacy of others\n'
              '• Complying with all applicable laws and regulations',
            ),
            
            _buildSection(
              context,
              '4. Emergency Services',
              'The panic button feature will alert your emergency contacts and authorities. This is a serious function that should only be used in genuine emergencies. False alarms may result in:\n\n'
              '• Account suspension or termination\n'
              '• Legal consequences if authorities respond\n'
              '• Liability for wasted emergency resources\n\n'
              'We are not responsible for emergency response times or outcomes.',
            ),
            
            _buildSection(
              context,
              '5. Crime Reporting',
              'Crime reports submitted through the App:\n\n'
              '• Will be shared with local law enforcement\n'
              '• Must be accurate and truthful\n'
              '• May be used as evidence in investigations\n'
              '• Cannot be edited after submission (contact support for corrections)\n'
              '• Anonymous reports are handled according to local laws',
            ),
            
            _buildSection(
              context,
              '6. Data Collection & Privacy',
              'We collect location data, crime reports, and personal information as described in our Privacy Policy. By using the App, you consent to:\n\n'
              '• Collection of your location data\n'
              '• Sharing information with law enforcement\n'
              '• Storage of your reports and alerts\n'
              '• Use of data for service improvement',
            ),
            
            _buildSection(
              context,
              '7. Prohibited Uses',
              'You may not use the App to:\n\n'
              '• Submit false or misleading information\n'
              '• Harass, threaten, or harm others\n'
              '• Use the App for illegal purposes\n'
              '• Attempt to hack or disrupt the service\n'
              '• Share your account with others\n'
              '• Impersonate another person or entity\n'
              '• Spam or send unsolicited messages',
            ),
            
            _buildSection(
              context,
              '8. Limitation of Liability',
              'The App is provided "as is" without warranties of any kind. We are not liable for:\n\n'
              '• Emergency response times or outcomes\n'
              '• Accuracy of user-submitted information\n'
              '• Service interruptions or downtime\n'
              '• Loss of data or content\n'
              '• Direct, indirect, or consequential damages\n\n'
              'Your use of emergency services through the App does not guarantee a response.',
            ),
            
            _buildSection(
              context,
              '9. Account Termination',
              'We reserve the right to terminate or suspend accounts that:\n\n'
              '• Violate these terms of service\n'
              '• Submit false reports or alerts\n'
              '• Engage in prohibited activities\n'
              '• Abuse the service or emergency features\n\n'
              'You may request account deletion at any time through the profile settings.',
            ),
            
            _buildSection(
              context,
              '10. Indemnification',
              'You agree to indemnify and hold harmless 3:11 Security, its officers, directors, employees, and agents from any claims, damages, or expenses arising from your use of the App or violation of these terms.',
            ),
            
            _buildSection(
              context,
              '11. Changes to Terms',
              'We may update these terms at any time. Significant changes will be communicated through the App or via email. Continued use of the App after changes constitutes acceptance of the updated terms.',
            ),
            
            _buildSection(
              context,
              '12. Governing Law',
              'These terms are governed by the laws of Namibia. Any disputes will be resolved in the courts of Namibia.',
            ),
            
            _buildSection(
              context,
              '13. Contact Information',
              'For questions about these terms, contact us at:\n\n'
              'Email: support@311security.na\n'
              'Phone: +264 61 311 3110\n'
              'Address: Windhoek, Namibia',
            ),
            
            const SizedBox(height: 32),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'By using 3:11 Security, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade900,
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

