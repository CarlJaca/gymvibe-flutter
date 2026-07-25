import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/super_admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/app_settings_model.dart';

class SuperAdminSettingsScreen extends StatefulWidget {
  const SuperAdminSettingsScreen({super.key});

  @override
  State<SuperAdminSettingsScreen> createState() => _SuperAdminSettingsScreenState();
}

class _SuperAdminSettingsScreenState extends State<SuperAdminSettingsScreen> {
  AppSettingsModel _settings = const AppSettingsModel();
  final _emailCtrl = TextEditingController();
  final _radiusCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<SuperAdminProvider>().loadSettings();
      _initForm();
    });
  }

  void _initForm() {
    if (!mounted) return;
    _settings = context.read<SuperAdminProvider>().settings;
    _emailCtrl.text = _settings.supportEmail;
    _radiusCtrl.text = _settings.defaultSearchRadiusKm.toString();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SuperAdminProvider>();

    if (provider.isLoading && provider.settings.supportEmail.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppPadding.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Settings', style: Theme.of(context).textTheme.headlineLarge),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _saveSettings,
                icon: const Icon(Icons.save, size: 18),
                label: const Text('Save Changes'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildSection('General', [
            _buildTextField('Support Email', _emailCtrl, Icons.email_outlined),
            const SizedBox(height: 16),
            _buildTextField('Default Search Radius (km)', _radiusCtrl, Icons.map_outlined, isNumber: true),
          ]),
          const SizedBox(height: 24),

          _buildSection('System Access', [
            SwitchListTile(
              title: const Text('Registration Enabled', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: const Text('Allow new users to sign up', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              value: _settings.registrationEnabled,
              activeThumbColor: AppColors.primary,
              onChanged: (v) => setState(() => _settings = _settings.copyWith(registrationEnabled: v)),
            ),
            const Divider(color: AppColors.border),
            SwitchListTile(
              title: const Text('Maintenance Mode', style: TextStyle(color: AppColors.error)),
              subtitle: const Text('Disable app access for all non-admin users', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              value: _settings.maintenanceMode,
              activeThumbColor: AppColors.error,
              onChanged: (v) => setState(() => _settings = _settings.copyWith(maintenanceMode: v)),
            ),
          ]),
          const SizedBox(height: 24),

          _buildSection('Leaderboard Categories', [
            _buildListEditor(_settings.leaderboardCategories, (newList) {
              setState(() => _settings = _settings.copyWith(leaderboardCategories: newList));
            }),
          ]),
          const SizedBox(height: 24),

          _buildSection('Report Reasons', [
            _buildListEditor(_settings.reportReasons, (newList) {
              setState(() => _settings = _settings.copyWith(reportReasons: newList));
            }),
          ]),
          const SizedBox(height: 24),

          _buildSection('Suspension Reasons', [
            _buildListEditor(_settings.suspensionReasons, (newList) {
              setState(() => _settings = _settings.copyWith(suspensionReasons: newList));
            }),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, IconData icon, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildListEditor(List<String> items, Function(List<String>) onChanged) {
    final newCtrl = TextEditingController();
    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(color: AppColors.border),
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(items[index], style: const TextStyle(fontSize: 13)),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                onPressed: () {
                  final newList = List<String>.from(items)..removeAt(index);
                  onChanged(newList);
                },
              ),
            );
          },
        ),
        if (items.isNotEmpty) const Divider(color: AppColors.border),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: newCtrl,
                decoration: const InputDecoration(
                  hintText: 'Add new item...',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppColors.primary),
              onPressed: () {
                if (newCtrl.text.trim().isNotEmpty) {
                  final newList = List<String>.from(items)..add(newCtrl.text.trim());
                  onChanged(newList);
                  newCtrl.clear();
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  void _saveSettings() {
    final authProvider = context.read<AuthProvider>();
    final newSettings = _settings.copyWith(
      supportEmail: _emailCtrl.text.trim(),
      defaultSearchRadiusKm: double.tryParse(_radiusCtrl.text) ?? 10.0,
    );
    context.read<SuperAdminProvider>().updateSettings(
      settings: newSettings,
      adminId: authProvider.currentUser!.id,
      adminName: authProvider.userName,
    );
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved successfully')));
  }
}
