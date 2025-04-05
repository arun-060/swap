import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../providers/language_provider.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fixedAddressController = TextEditingController();
  final _deliveryAddressController = TextEditingController();
  bool _isLoading = true;
  bool _useFixedAddress = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    try {
      setState(() => _isLoading = true);
      final supabaseClient = supabase.Supabase.instance.client;
      final user = supabaseClient.auth.currentUser;
      if (user == null) return;

      final response = await supabaseClient
          .from('user_addresses')
          .select()
          .eq('user_id', user.id)
          .single();

      setState(() {
        _fixedAddressController.text = response['fixed_address'] ?? '';
        _deliveryAddressController.text = response['delivery_address'] ?? '';
        _useFixedAddress = response['use_fixed_address'] ?? true;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading addresses: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveAddresses() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);
      final supabaseClient = supabase.Supabase.instance.client;
      final user = supabaseClient.auth.currentUser;
      if (user == null) return;

      await supabaseClient.from('user_addresses').upsert({
        'user_id': user.id,
        'fixed_address': _fixedAddressController.text,
        'delivery_address': _deliveryAddressController.text,
        'use_fixed_address': _useFixedAddress,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Addresses saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving addresses: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.getTranslatedText('location')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fixed Address Section
                    Text(
                      languageProvider.getTranslatedText('fixed_address'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      languageProvider.getTranslatedText('fixed_address_desc'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _fixedAddressController,
                      decoration: InputDecoration(
                        labelText: languageProvider.getTranslatedText('address'),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.home_outlined),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (_useFixedAddress && (value == null || value.isEmpty)) {
                          return languageProvider
                              .getTranslatedText('address_required');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Delivery Address Section
                    Text(
                      languageProvider.getTranslatedText('delivery_address'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      languageProvider.getTranslatedText('delivery_address_desc'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _deliveryAddressController,
                      decoration: InputDecoration(
                        labelText:
                            languageProvider.getTranslatedText('delivery_address'),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.local_shipping_outlined),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (!_useFixedAddress &&
                            (value == null || value.isEmpty)) {
                          return languageProvider
                              .getTranslatedText('address_required');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Use Fixed Address Switch
                    SwitchListTile(
                      title: Text(
                        languageProvider.getTranslatedText('use_fixed_address'),
                      ),
                      subtitle: Text(
                        languageProvider.getTranslatedText('use_fixed_address_desc'),
                      ),
                      value: _useFixedAddress,
                      onChanged: (value) {
                        setState(() => _useFixedAddress = value);
                      },
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveAddresses,
                        child: Text(languageProvider.getTranslatedText('save')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _fixedAddressController.dispose();
    _deliveryAddressController.dispose();
    super.dispose();
  }
} 