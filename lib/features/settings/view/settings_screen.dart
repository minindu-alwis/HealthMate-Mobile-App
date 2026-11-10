import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/icon_circle.dart';
import '../../../core/widgets/large_header.dart';
import '../../records/model/health_record.dart';
import '../viewmodel/settings_view_model.dart';

const String appVersion = '1.0.0';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final Map<MetricKey, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    final vm = context.read<SettingsViewModel>();
    _controllers = {for (final key in MetricKey.values) key: TextEditingController(text: vm.valueOf(key))};
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), duration: const Duration(milliseconds: 2500)));
  }

  Future<void> _save(SettingsViewModel vm) async {
    FocusScope.of(context).unfocus();
    final message = await vm.save();
    if (message != null && mounted) _show(message);
  }

  Future<void> _confirm(SettingsViewModel vm, DataAction action) async {
    final deleteAll = action == DataAction.deleteAll;
    final confirmed = await showConfirmDialog(
      context,
      title: deleteAll ? 'Delete all records?' : 'Reload sample data?',
      message: deleteAll
          ? 'Every health record on this device will be permanently removed. This cannot be undone.'
          : 'Your current records will be replaced with 14 days of sample data for testing.',
      confirmLabel: deleteAll ? 'Delete all' : 'Reload',
      destructive: deleteAll,
    );
    if (!confirmed || !mounted) return;
    final message = await vm.perform(action);
    if (mounted) _show(message);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: darkStatusBar,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const LargeHeader(title: 'Settings', subtitle: 'Goals, data and app information'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    const _SectionTitle('DAILY GOALS'),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                      decoration: cardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final key in MetricKey.values)
                            _GoalField(
                              metric: key,
                              controller: _controllers[key]!,
                              errorText: vm.errorFor(key),
                              onChanged: (text) => vm.setGoal(key, text),
                            ),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 48,
                            child: FilledButton.icon(
                              onPressed: vm.busy ? null : () => _save(vm),
                              icon: const Icon(Icons.track_changes),
                              label: const Text('Save goals'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const _SectionTitle('DATA'),
                    _Card(
                      children: [
                        _Row(
                          icon: Icons.settings_backup_restore,
                          iconColor: AppColors.primary,
                          iconBackground: AppColors.surfaceVariant,
                          title: 'Reload sample data',
                          subtitle: 'Replace records with 14 days of test data',
                          onTap: vm.busy ? null : () => _confirm(vm, DataAction.reloadSamples),
                        ),
                        _Row(
                          icon: Icons.delete_forever,
                          iconColor: AppColors.error,
                          iconBackground: AppColors.errorContainer,
                          title: 'Delete all records',
                          titleColor: AppColors.error,
                          subtitle: 'Permanently clear your history',
                          onTap: vm.busy ? null : () => _confirm(vm, DataAction.deleteAll),
                        ),
                      ],
                    ),
                    const _SectionTitle('ABOUT'),
                    const _Card(
                      children: [
                        _Row(
                          icon: Icons.monitor_heart_outlined,
                          iconColor: AppColors.primary,
                          iconBackground: AppColors.surfaceVariant,
                          title: 'HealthMate',
                          subtitle: 'Version $appVersion · Personal health & wellness tracker',
                        ),
                        _Row(
                          icon: Icons.shield_outlined,
                          iconColor: AppColors.primary,
                          iconBackground: AppColors.surfaceVariant,
                          title: 'Your data stays on this device',
                          subtitle: 'Stored locally in SQLite. No account or internet needed.',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.primary, letterSpacing: 1),
        ),
      ),
    );
  }
}

class _GoalField extends StatelessWidget {
  const _GoalField({required this.metric, required this.controller, required this.onChanged, this.errorText});

  final MetricKey metric;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final style = metricStyles[metric]!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, left: 8),
            child: IconCircle(
              icon: style.icon,
              color: style.color,
              background: style.container,
              size: 36,
              iconSize: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              keyboardType: TextInputType.number,
              inputFormatters: [LengthLimitingTextInputFormatter(6)],
              decoration: InputDecoration(
                labelText: '${style.shortLabel} goal',
                suffixText: style.unit,
                errorText: errorText,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: style.color, width: 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[if (i > 0) const Divider(indent: 64), children[i]],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    this.titleColor,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final Color? titleColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: IconCircle(icon: icon, color: iconColor, background: iconBackground, size: 36, iconSize: 20),
      title: Text(title, style: TextStyle(color: titleColor ?? AppColors.onSurface, fontSize: 16)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.onSurfaceVariant)),
      onTap: onTap,
    );
  }
}
