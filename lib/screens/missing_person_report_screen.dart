import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:security_311_user/models/missing_report.dart';
import 'package:security_311_user/providers/auth_provider.dart';
import 'package:security_311_user/providers/missing_reports_provider.dart';
import 'package:security_311_user/services/missing_report_service.dart';
import 'package:security_311_user/services/storage_service.dart';
import 'package:security_311_user/core/logger.dart';

class MissingPersonReportScreen extends StatefulWidget {
  const MissingPersonReportScreen({super.key});

  @override
  State<MissingPersonReportScreen> createState() =>
      _MissingPersonReportScreenState();
}

class _MissingPersonReportScreenState extends State<MissingPersonReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _personNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _contactEmailController = TextEditingController();
  DateTime? _lastSeenDate;
  MissingReportType _selectedType = MissingReportType.missingPerson;
  bool _isSubmitting = false;

  final ImagePicker _imagePicker = ImagePicker();
  final List<XFile> _photos = [];

  final MissingReportService _missingReportService = MissingReportService();
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MissingReportsProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _personNameController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Missing Person • Lost & Found'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Report Details',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SegmentedButton<MissingReportType>(
                segments: const [
                  ButtonSegment(
                    value: MissingReportType.missingPerson,
                    label: Text('Missing Person'),
                    icon: Icon(Icons.person_search),
                  ),
                  ButtonSegment(
                    value: MissingReportType.lostItem,
                    label: Text('Lost Item'),
                    icon: Icon(Icons.backpack),
                  ),
                  ButtonSegment(
                    value: MissingReportType.foundPerson,
                    label: Text('Found'),
                    icon: Icon(Icons.people),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (value) {
                  setState(() {
                    _selectedType = value.first;
                  });
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Headline *',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              if (_selectedType != MissingReportType.lostItem) ...[
                TextFormField(
                  controller: _personNameController,
                  decoration: const InputDecoration(
                    labelText: 'Person Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ageController,
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    prefixIcon: Icon(Icons.cake),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Last seen / Lost at *',
                  prefixIcon: Icon(Icons.location_pin),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: Text(
                  _lastSeenDate == null
                      ? 'Select last seen date'
                      : 'Last seen: ${_formatDate(_lastSeenDate!)}',
                ),
                trailing: TextButton(
                  onPressed: _pickDate,
                  child: const Text('Choose'),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                minLines: 4,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Contact Phone *',
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactEmailController,
                decoration: const InputDecoration(
                  labelText: 'Contact Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              Text(
                'Photos (optional)',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final photo in _photos)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(photo.path),
                            width: 110,
                            height: 110,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _photos.remove(photo);
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (_photos.length < 4)
                    GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.4),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(height: 4),
                            const Text('Add Photo'),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(_isSubmitting
                      ? 'Submitting for admin approval...'
                      : 'Submit for Approval'),
                ),
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 24),
              const _ApprovedReportsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    try {
      final picked = await _imagePicker.pickMultiImage(imageQuality: 85);
      if (picked.isNotEmpty) {
        setState(() {
          _photos
            ..clear()
            ..addAll(picked.take(4));
        });
      }
    } catch (e) {
      AppLogger.error('Image selection error', e);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _lastSeenDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
    );
    if (selected != null) {
      setState(() {
        _lastSeenDate = selected;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      List<String> photoUrls = [];
      if (_photos.isNotEmpty) {
        final user = context.read<AuthProvider>().user;
        if (user == null) {
          throw Exception('User not authenticated');
        }
        try {
          photoUrls = await _storageService.uploadMultipleEvidenceImages(
            userId: user.id,
            images: _photos,
            bucketName: 'missing-reports',
            folderPrefix: 'missing',
          );
        } catch (e) {
          AppLogger.error('Failed to upload missing report images', e);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to upload images: $e'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          // Continue submission with whatever uploaded successfully
          photoUrls = photoUrls; // keep current (likely empty)
        }
      }

      final success = await _missingReportService.createMissingReport(
        reportType: _selectedType,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        personName: _personNameController.text.trim().isEmpty
            ? null
            : _personNameController.text.trim(),
        age: _ageController.text.trim().isEmpty
            ? null
            : int.tryParse(_ageController.text.trim()),
        lastSeenLocation: _locationController.text.trim(),
        lastSeenDate: _lastSeenDate,
        contactPhone: _contactPhoneController.text.trim(),
        contactEmail: _contactEmailController.text.trim().isEmpty
            ? null
            : _contactEmailController.text.trim(),
        photoUrls: photoUrls,
      );

      if (!mounted) return;

      if (success) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Submitted for Approval'),
            content: const Text(
                'Your report has been sent to the admin team for review. '
                'Once approved it will appear on the platform.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        _resetForm();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit report. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _titleController.clear();
    _descriptionController.clear();
    _personNameController.clear();
    _ageController.clear();
    _locationController.clear();
    _contactPhoneController.clear();
    _contactEmailController.clear();
    _photos.clear();
    _lastSeenDate = null;
    setState(() {
      _selectedType = MissingReportType.missingPerson;
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _ApprovedReportsSection extends StatelessWidget {
  const _ApprovedReportsSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<MissingReportsProvider>(
      builder: (context, provider, child) {
        final theme = Theme.of(context);
        final hasData = provider.hasReports;

        if (provider.isLoading && !hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorMessage != null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Community Lost & Found',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                provider.errorMessage!,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.error),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: provider.loadApprovedReports,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          );
        }

        final missingReports =
            provider.reportsForType(MissingReportType.missingPerson);
        final lostReports = provider.reportsForType(MissingReportType.lostItem);
        final foundReports =
            provider.reportsForType(MissingReportType.foundPerson);

        if (!hasData) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Community Lost & Found',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Approved lost items, found cases, and missing person alerts will appear here once published by the admin team.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          );
        }

        final sections = <Widget>[];

        if (lostReports.isNotEmpty) {
          sections.add(
            _ReportsCarousel(
              title: 'Approved Lost Items',
              subtitle: 'Recently published lost item notices with photos',
              reports: lostReports,
            ),
          );
        }

        if (foundReports.isNotEmpty) {
          sections.add(
            _ReportsCarousel(
              title: 'Found Items',
              subtitle: 'Recovered belongings awaiting pickup',
              reports: foundReports,
            ),
          );
        }

        if (missingReports.isNotEmpty) {
          sections.add(
            _ReportsCarousel(
              title: 'Missing Persons',
              subtitle: 'Active missing person alerts',
              reports: missingReports,
            ),
          );
        }

        if (sections.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Community Lost & Found',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'No approved reports yet. Check back soon or submit a new report above.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Community Lost & Found',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Browse the latest approved lost, found, and missing person alerts. Tap on any card to contact the poster.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            if (provider.isLoading)
              LinearProgressIndicator(
                minHeight: 3,
                backgroundColor:
                    theme.colorScheme.primary.withValues(alpha: 0.1),
              ),
            ...sections
                .expand((section) => [section, const SizedBox(height: 24)]),
          ],
        );
      },
    );
  }
}

class _ReportsCarousel extends StatelessWidget {
  const _ReportsCarousel({
    required this.title,
    required this.subtitle,
    required this.reports,
  });

  final String title;
  final String subtitle;
  final List<MissingReport> reports;

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 280,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final report = reports[index];
              return _MissingReportShowcaseCard(report: report);
            },
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemCount: reports.length,
          ),
        ),
      ],
    );
  }
}

class _MissingReportShowcaseCard extends StatelessWidget {
  const _MissingReportShowcaseCard({required this.report});

  final MissingReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photo =
        report.photoUrls?.isNotEmpty == true ? report.photoUrls!.first : null;

    return Container(
      width: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: photo != null
                  ? Image.network(
                      photo,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _ImageFallback(
                        icon: Icons.image_not_supported,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : _ImageFallback(
                      icon: Icons.camera_alt_outlined,
                      color: theme.colorScheme.primary,
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Chip(
                  label: Text(report.reportType.displayLabel),
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.12),
                  labelStyle: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  report.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (report.lastSeenLocation != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_pin,
                        size: 16,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          report.lastSeenLocation!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  report.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Contact: ${report.contactPhone ?? 'Not provided'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (report.contactEmail != null &&
                    report.contactEmail!.isNotEmpty)
                  Text(
                    report.contactEmail!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withValues(alpha: 0.1),
      child: Center(
        child: Icon(
          icon,
          color: color.withValues(alpha: 0.7),
          size: 32,
        ),
      ),
    );
  }
}
