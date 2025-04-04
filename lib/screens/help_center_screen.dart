import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/language_provider.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<XFile> _screenshots = [];
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() {
        _screenshots.add(image);
      });
    } catch (e) {
      setState(() {
        _error = 'Error picking image: $e';
      });
    }
  }

  Future<void> _removeImage(int index) async {
    setState(() {
      _screenshots.removeAt(index);
    });
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // TODO: Implement report submission
      await Future.delayed(const Duration(seconds: 2)); // Simulated API call

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<LanguageProvider>().getTranslatedText('report_submitted'),
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _error = 'Error submitting report: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<LanguageProvider>().getTranslatedText('url_launch_error'),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.getTranslatedText('help_center')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      languageProvider.getTranslatedText('contact_us'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.email),
                      title: Text(languageProvider.getTranslatedText('email')),
                      subtitle: const Text('support@swap.app'),
                      onTap: () => _launchUrl('mailto:support@swap.app'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.phone),
                      title: Text(languageProvider.getTranslatedText('phone')),
                      subtitle: const Text('+1 234 567 8900'),
                      onTap: () => _launchUrl('tel:+12345678900'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.web),
                      title: Text(languageProvider.getTranslatedText('website')),
                      subtitle: const Text('www.swap.app'),
                      onTap: () => _launchUrl('https://www.swap.app'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        languageProvider.getTranslatedText('report_issue'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _subjectController,
                        decoration: InputDecoration(
                          labelText: languageProvider.getTranslatedText('subject'),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return languageProvider.getTranslatedText('subject_required');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: languageProvider.getTranslatedText('description'),
                          border: const OutlineInputBorder(),
                        ),
                        maxLines: 5,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return languageProvider.getTranslatedText('description_required');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        languageProvider.getTranslatedText('screenshots'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (_screenshots.isNotEmpty)
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _screenshots.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Stack(
                                  children: [
                                    Image.network(
                                      _screenshots[index].path,
                                      height: 100,
                                      width: 100,
                                      fit: BoxFit.cover,
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: IconButton(
                                        icon: const Icon(Icons.close),
                                        onPressed: () => _removeImage(index),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.add_photo_alternate),
                        label: Text(languageProvider.getTranslatedText('add_screenshot')),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitReport,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: _isLoading
                                ? const CircularProgressIndicator()
                                : Text(
                                    languageProvider.getTranslatedText('submit_report'),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 