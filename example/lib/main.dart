import 'package:bee_dynamic_launcher/bee_dynamic_launcher.dart';
import 'package:bee_dynamic_launcher_example/app/app_theme.dart';
import 'package:bee_dynamic_launcher_example/widgets/catalog_error_view.dart';
import 'package:bee_dynamic_launcher_example/widgets/catalog_loading_view.dart';
import 'package:bee_dynamic_launcher_example/widgets/launcher_preview_card.dart';
import 'package:bee_dynamic_launcher_example/widgets/launcher_variants_section.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BeeLauncherExampleApp());
}

class BeeLauncherExampleApp extends StatelessWidget {
  const BeeLauncherExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bee Dynamic Launcher',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ExampleAppTheme.light(),
      darkTheme: ExampleAppTheme.dark(),
      home: const LauncherSettingsPage(),
    );
  }
}

class LauncherSettingsPage extends StatefulWidget {
  const LauncherSettingsPage({super.key});

  @override
  State<LauncherSettingsPage> createState() => _LauncherSettingsPageState();
}

class _LauncherSettingsPageState extends State<LauncherSettingsPage> {
  bool _loading = true;
  String? _errorMessage;
  List<LauncherVariantEntry> _entries = const [];
  String? _currentVariantId;
  String? _busyVariantId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      await LauncherCatalog.instance.loadFromBundle();
      await BeeDynamicLauncher.initializeFromCatalog();
      final current = await BeeDynamicLauncher.getCurrentVariant();
      if (!mounted) {
        return;
      }
      setState(() {
        _entries = LauncherCatalog.instance.variants;
        _currentVariantId = current ?? LauncherCatalog.instance.primaryVariantId;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _apply(LauncherVariantEntry entry) async {
    if (_busyVariantId != null || entry.id == _currentVariantId) {
      return;
    }
    setState(() => _busyVariantId = entry.id);
    try {
      await BeeDynamicLauncher.applyVariant(entry.id);
      final current = await BeeDynamicLauncher.getCurrentVariant();
      if (!mounted) {
        return;
      }
      setState(() => _currentVariantId = current ?? entry.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Home icon set to "${entry.displayName}"'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      final scheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not apply: $e',
            style: TextStyle(color: scheme.onError),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: scheme.error,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busyVariantId = null);
      }
    }
  }

  String _labelForId(String id) => LauncherCatalog.instance.displayNameFor(id);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: CatalogLoadingView());
    }
    if (_errorMessage != null) {
      return Scaffold(
        body: CatalogErrorView(
          message: _errorMessage!,
          onRetry: _load,
        ),
      );
    }

    final currentId = _currentVariantId;
    final currentLabel = currentId == null ? null : _labelForId(currentId);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Launcher Variants', style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 15.5,
              letterSpacing: -0.1,
            ),),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Reload catalog',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      backgroundColor: scheme.brightness == Brightness.light
          ? const Color(0xFFF4F5F7)
          : Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            if (currentId != null && currentLabel != null) ...[
              const _SectionTitle('Current Launcher'),
              const SizedBox(height: 8),
              LauncherPreviewCard(
                title: currentLabel,
                variantId: currentId,
                activeIconAssetPath: launcherIconPreviewAssetPath(currentId),
              ),
              const SizedBox(height: 14),
            ],
            const _SectionTitle('Icon Variants'),
            const SizedBox(height: 8),
            LauncherVariantsSection(
              entries: _entries,
              currentVariantId: currentId,
              busyVariantId: _busyVariantId,
              onApply: _apply,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.1,
            ),
      ),
    );
  }
}
