// Plately — Scan Screen
// =======================
// Camera-based ingredient scanning with AI recognition.
// Captures an image, sends to the backend vision API,
// and displays results in 3 confidence tiers: auto-add, confirm, or correct.

import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plately_app/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plately_app/core/services/api_service.dart';
import 'package:plately_app/core/services/auth_helper.dart';
import 'package:plately_app/core/utils/category_images.dart';
import 'package:plately_app/core/utils/l10n_helper.dart';
import 'package:plately_app/features/scan/presentation/screens/audit_screen.dart';
import 'package:plately_app/core/services/tutorial_controller.dart';
import 'package:plately_app/features/profile/presentation/screens/nutrition_tracker_page.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final ApiService _api = ApiService();

  bool _scanning = false;
  // 0 = Receipt, 1 = Photo, 2 = Barcode
  int _scanMode = 0;
  late TabController _topTabController;
  Map<String, dynamic>? _results;
  String? _error;
  late AnimationController _pulseController;
  final Set<int> _addedIndices = {};

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _topTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _topTabController.dispose();
    _pulseController.dispose();
    _api.dispose();
    super.dispose();
  }

  Future<void> _enrichItemsWithDb(Map<String, dynamic> data) async {
    final items = (data['items'] as List?) ?? [];
    for (var idx = 0; idx < items.length; idx++) {
      final i = items[idx];
      if (i is! Map<String, dynamic>) continue;
      
      final name = i['canonical_name'] ?? i['item_name'] ?? '';
      if (name.toString().trim().isEmpty) continue;
      
      try {
        final matches = await _api.searchIngredients(name.toString(), limit: 1);
        if (matches.isNotEmpty) {
          final match = matches.first;
          // Prefer DB category
          i['category'] = match['category'] ?? i['category'];
          // Prefer DB unit if none provided
          i['unit'] = i['unit'] ?? match['default_unit'];
          
          // Copy translations to item map
          i['display_name_en'] = match['display_name_en'];
          i['display_name_ko'] = match['display_name_ko'];
          i['display_name_uz'] = match['display_name_uz'];
          i['display_name_uz_cyrl'] = match['display_name_uz_cyrl'];
          i['display_name_ru'] = match['display_name_ru'];
          
          // Auto-fill expiry based on DB shelf life if missing
          if (i['expiry_date'] == null && match['sealed_shelf_life_days'] != null) {
            final days = match['sealed_shelf_life_days'];
            if (days is num && days > 0) {
              i['expiry_date'] = DateTime.now().add(Duration(days: days.toInt())).toIso8601String();
            }
          }
        }
      } catch (e) {
        debugPrint('Enrichment failed for $name: $e');
      }
    }
  }

  Future<void> _captureImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (image == null) return;

      setState(() {
        _scanning = true;
        _error = null;
        _results = null;
      });

      final Uint8List bytes = await image.readAsBytes();

      // Send to FastAPI -> Gemini Vision Endpoint
      final result = await _api.parseReceipt(
        imageBytes: bytes,
        filename: image.name,
        lang: Localizations.localeOf(context).languageCode,
      );

      final data = (result['data'] as Map<String, dynamic>?) ?? result;
      final itemsList = (data['items'] as List?) ?? [];
      if (itemsList.isEmpty) {
        setState(() {
          _error = AppLocalizations.of(context)?.recognitionFailed ??
              'No items detected in receipt. Please try a clearer photo with good lighting.';
          _scanning = false;
        });
        return;
      }
      await _enrichItemsWithDb(data);

      setState(() {
        // Backend wraps in {status, source, data: {store, date, items}}
        _results = data;
        _scanning = false;
        _addedIndices.clear();
      });
    } catch (e) {
      setState(() {
        _error = _cleanScanError(e);
        _scanning = false;
      });
    }
  }

  String _cleanScanError(dynamic e) {
    final msg = e.toString();
    final l10n = AppLocalizations.of(context);
    if (msg.contains('timed out') || msg.contains('Timeout')) {
      return l10n?.recognitionFailed ?? 'Scanning timed out. Please check your connection and try again.';
    }
    if (msg.contains('SocketException') || msg.contains('Connection refused') || msg.contains('Failed host lookup')) {
      return l10n?.recognitionFailed ?? 'Cannot reach scanning server. Please check your internet connection.';
    }
    return l10n?.recognitionFailed ?? 'Recognition failed. Please try a clearer photo.';
  }

  /// Capture a photo for ingredient detection (not receipts)
  Future<void> _capturePhoto(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (image == null) return;

      setState(() {
        _scanning = true;
        _error = null;
        _results = null;
      });

      final Uint8List bytes = await image.readAsBytes();

      final result = await _api.detectIngredients(
        imageBytes: bytes,
        filename: image.name,
      );

      final data = (result['data'] as Map<String, dynamic>?) ?? result;
      final itemsList = (data['items'] as List?) ?? [];
      if (itemsList.isEmpty) {
        setState(() {
          _error = AppLocalizations.of(context)?.recognitionFailed ??
              'No food ingredients detected. Please try a clearer photo with food clearly visible.';
          _scanning = false;
        });
        return;
      }
      await _enrichItemsWithDb(data);

      setState(() {
        // Backend wraps in {status, source, data: {items: [...]}}
        _results = data;
        _scanning = false;
        _addedIndices.clear();
      });
    } catch (e) {
      setState(() {
        _error = _cleanScanError(e);
        _scanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.auto_scan ?? 'Scan', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        bottom: TabBar(
          controller: _topTabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          indicatorWeight: 3,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
          labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          tabs: [
            Tab(icon: Icon(Icons.fastfood, size: 20), text: AppLocalizations.of(context)?.scanFood ?? 'Scan Food'),
            Tab(icon: Icon(Icons.local_fire_department, size: 20), text: AppLocalizations.of(context)?.scanCaloriesTab ?? 'Scan Calories'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _topTabController,
        children: [
          // Tab 1: Scan Food (existing)
          ref.watch(tutorialControllerProvider) == TutorialState.scanIntro
              ? _buildTutorialScanPrompt()
              : _scanning
                  ? _buildScanningState()
                  : _results != null
                      ? _buildResults()
                      : _buildCaptureState(),
          // Tab 2: Scan Calories (photo-based)
          const _CalorieScanTab(),
        ],
      ),
    );
  }

  // ── Capture State (initial) ──────────────────────────────────────

  Widget _buildCaptureState() {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(32, 32, 32, 120),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated scan icon
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + _pulseController.value * 0.08,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.document_scanner_outlined,
                      size: 56,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: 32),

            Text(
              AppLocalizations.of(context)?.scanYourIngredients ?? 'Scan Your Ingredients',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)?.takeAPhotoOfFoodItems ?? 'Take a photo of food items to add them\nto your shelf automatically',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 14,
                height: 1.5,
              ),
            ),

            SizedBox(height: 24),

            // ── Mode Toggle ──────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  _ModeTab(
                    icon: Icons.receipt_long,
                    label: AppLocalizations.of(context)?.scanReceipt ?? 'Receipt',
                    isActive: _scanMode == 0,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onTap: () => setState(() => _scanMode = 0),
                  ),
                  _ModeTab(
                    icon: Icons.photo_camera,
                    label: AppLocalizations.of(context)?.scanPhoto ?? 'Photo',
                    isActive: _scanMode == 1,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onTap: () => setState(() => _scanMode = 1),
                  ),
                  _ModeTab(
                    icon: Icons.qr_code_scanner,
                    label: AppLocalizations.of(context)?.scanBarcodeShort ?? 'Barcode',
                    isActive: _scanMode == 2,
                    activeColor: Theme.of(context).colorScheme.secondary,
                    onTap: () => setState(() => _scanMode = 2),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Camera button
            if (_scanMode != 2 && _scanMode != 3) ...[
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: () => _scanMode == 0
                      ? _captureImage(ImageSource.camera)
                      : _capturePhoto(ImageSource.camera),
                  icon: Icon(Icons.camera_alt, size: 22),
                  label: Text(
                    AppLocalizations.of(context)?.takePhoto ?? 'Take Photo',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],

            // Barcode scan button
            if (_scanMode == 2) ...[
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: _openBarcodeScanner,
                  icon: Icon(Icons.qr_code_scanner, size: 22),
                  label: Text(
                    AppLocalizations.of(context)?.scanBarcode ?? 'Scan Barcode',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],

            SizedBox(height: 12),

            // Gallery button
            if (_scanMode != 2 && _scanMode != 3) ...[
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () => _scanMode == 0
                      ? _captureImage(ImageSource.gallery)
                      : _capturePhoto(ImageSource.gallery),
                  icon: Icon(Icons.photo_library,
                      size: 22, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                  label: Text(
                    AppLocalizations.of(context)?.chooseFromGallery ?? 'Choose from Gallery',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
            
            SizedBox(height: 12),


            
            // Manual Entry Button

            SizedBox(
              width: double.infinity,
              height: 56,
              child: TextButton.icon(
                onPressed: _showManualEntryForm,
                icon: Icon(Icons.edit_note, size: 22, color: Theme.of(context).colorScheme.primary),
                label: Text(
                  AppLocalizations.of(context)?.addManually ?? 'Add Manually',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),

            // Error message
            if (_error != null) ...[
              SizedBox(height: 24),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                            color: Colors.red.withValues(alpha: 0.8),
                            fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Scanning State (loading) ─────────────────────────────────────

  Widget _buildScanningState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
              strokeWidth: 3,
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            ),
          ),
          SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)?.analyzingYourFood ?? 'Analyzing your food...',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)?.aiIsIdentifying ?? 'AI is identifying ingredients',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ── Results State (Parsed Receipt) ───────────────────────────────

  Widget _buildResults() {
    final data = _results;
    if (data == null) return _buildCaptureState();

    final store = data['store'] as String? ?? 'Unknown Store';
    final date = data['date'] as String? ?? 'Unknown Date';
    final items = (data['items'] as List?) ?? [];

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Header
          if (_scanMode == 0)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                    Theme.of(context).colorScheme.surface,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long,
                    color: Theme.of(context).colorScheme.primary,
                    size: 40,
                  ),
                  SizedBox(height: 12),
                  Text(
                    store,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4),
                  Text(
                    date,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      AppLocalizations.of(context)?.nItemsDetected(items.length.toString()) ?? '${items.length} Items Detected',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.tertiary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                    Theme.of(context).colorScheme.surface,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                   Icon(
                    Icons.image_search,
                    color: Theme.of(context).colorScheme.primary,
                    size: 40,
                  ),
                  SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context)?.photoAnalysisSelected ?? 'Photo Analysis Selected',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      AppLocalizations.of(context)?.nIngredientsDetected(items.length.toString()) ?? '${items.length} Ingredients Detected',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.tertiary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              ),
            ),

          SizedBox(height: 16),

          // ── Summary counter + Add All ──
          if (items.isNotEmpty) ...[
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    AppLocalizations.of(context)?.nOfNAdded(_addedIndices.length.toString(), items.length.toString()) ?? '${_addedIndices.length} / ${items.length} added',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                Spacer(),
                if (_addedIndices.length < items.length)
                  FilledButton.icon(
                    onPressed: () => _addAllToShelf(items),
                    icon: Icon(Icons.playlist_add_check, size: 18),
                    label: Text(AppLocalizations.of(context)?.auto_addAll ?? 'Add All'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.tertiary,
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      textStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  )
                else
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.check_circle, size: 16, color: Theme.of(context).colorScheme.tertiary),
                      SizedBox(width: 6),
                      Text(AppLocalizations.of(context)?.auto_allAdded ?? 'All Added',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.tertiary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
              ],
            ),
            SizedBox(height: 12),
          ],

          // Parsed Items List
          if (items.isNotEmpty) ...[
            _sectionHeader(
              '📦 Parsed Ingredients',
              'Review and add to shelf',
              Theme.of(context).colorScheme.onSurface,
            ),
            ...items.asMap().entries.map((entry) {
              final idx = entry.key;
              final i = entry.value as Map<String, dynamic>;
              
              // Get localized name based on app locale
              final localeCode = Localizations.localeOf(context).languageCode;
              final isUzCyrl = Localizations.localeOf(context).scriptCode == 'Cyrl';
              
              String displayName;
              if (localeCode == 'uz' && isUzCyrl) {
                displayName = i['display_name_uz_cyrl'] ?? i['display_name_uz'] ?? i['display_name_en'] ?? i['canonical_name'] ?? i['item_name'] ?? 'Unknown';
              } else {
                switch (localeCode) {
                  case 'uz':
                    displayName = i['display_name_uz'] ?? i['display_name_en'] ?? i['canonical_name'] ?? i['item_name'] ?? 'Unknown';
                    break;
                  case 'ko':
                    displayName = i['display_name_ko'] ?? i['display_name_en'] ?? i['canonical_name'] ?? i['item_name'] ?? 'Unknown';
                    break;
                  case 'ru':
                    displayName = i['display_name_ru'] ?? i['display_name_en'] ?? i['canonical_name'] ?? i['item_name'] ?? 'Unknown';
                    break;
                  default:
                    displayName = i['display_name_en'] ?? i['canonical_name'] ?? i['item_name'] ?? 'Unknown';
                }
              }

              final qty = i['quantity']?.toString() ?? '1';
              final unit = i['unit'] ?? '';
              final category = i['category'] ?? '';
              final expiry = i['expiry_date'] != null 
                  ? DateTime.parse(i['expiry_date']).toString().split(' ')[0] 
                  : 'Unknown';
              final isAdded = _addedIndices.contains(idx);

              return Opacity(
                opacity: isAdded ? 0.5 : 1.0,
                child: _resultTile(
                  icon: isAdded ? Icons.check_circle : Icons.check_circle_outline,
                  title: displayName,
                  subtitle: '$qty $unit • $category\nExp: $expiry',
                  color: isAdded ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4) : Theme.of(context).colorScheme.tertiary,
                  trailing: isAdded
                      ? Icon(Icons.done, color: Theme.of(context).colorScheme.tertiary)
                      : IconButton(
                          icon: Icon(Icons.add_shopping_cart, color: Theme.of(context).colorScheme.primary),
                          onPressed: () => _addSingleItem(i, idx),
                        ),
                ),
              );
            }),
          ],

          if (items.isEmpty) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Icon(Icons.search_off_rounded, size: 48, color: Theme.of(context).colorScheme.error),
                  SizedBox(height: 12),
                  Text(
                    _scanMode == 0
                        ? 'No readable items found on receipt'
                        : 'No identifiable food items found in photo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Try taking a clearer, well-lit photo with items fully visible, or add items manually below.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
          ],

          SizedBox(height: 32),

          // Scan again button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => setState(() {
                _results = null;
                _error = null;
                _addedIndices.clear();
              }),
              icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
              label: Text(AppLocalizations.of(context)?.auto_scanAnother ?? 'Scan Another', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          SizedBox(height: 12),

          // Audit Items Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: () {
                final itemsList = (_results?['items'] as List?) ?? [];
                if (itemsList.isEmpty) return;
                
                final auditItems = itemsList.map((i) {
                  final name = i['canonical_name'] ?? i['item_name'] ?? 'Unknown';
                  return AuditItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString() + math.Random().nextInt(1000).toString(),
                    title: name,
                    description: '${i['quantity'] ?? 1} ${i['unit'] ?? "pcs"} • Exp: ${i['expiry_date'] != null ? DateTime.parse(i['expiry_date']).toString().split(' ')[0] : 'Unknown'}',
                    category: i['category'] ?? 'Pantry',
                    rawDetect: name,
                  );
                }).toList();

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AuditScreen(initialItems: auditItems)),
                );
              },
              icon: Icon(Icons.style),
              label: Text(AppLocalizations.of(context)?.auto_startVisualAudit ?? 'Start Visual Audit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Add a single item to the shelf
  Future<void> _addSingleItem(Map<String, dynamic> i, int idx) async {
    final canonicalName = i['canonical_name'] ?? i['item_name'] ?? 'Unknown';
    final qty = i['quantity']?.toString() ?? '1';
    final unit = i['unit'] ?? '';
    final category = i['category'] ?? '';
    try {
      final userId = currentUserId();
      await _api.addInventoryItem(
        userId: userId,
        ingredientName: canonicalName,
        category: category.isNotEmpty ? category : 'Pantry',
        quantity: double.tryParse(qty) ?? 1.0,
        unit: unit.isEmpty ? 'pcs' : unit,
        location: 'Fridge',
        expiryDate: i['expiry_date'],
      );

      if (!mounted) return;
      setState(() => _addedIndices.add(idx));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.addedItem(canonicalName) ?? 'Added $canonicalName!'),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      debugPrint('Error adding to shelf: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.failedToAddItem(canonicalName) ?? 'Failed to add $canonicalName'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  /// Bulk-add all remaining items
  Future<void> _addAllToShelf(List items) async {
    final userId = currentUserId();
    int added = 0;

    for (int idx = 0; idx < items.length; idx++) {
      if (_addedIndices.contains(idx)) continue;
      final i = items[idx] as Map<String, dynamic>;
      final canonicalName = i['canonical_name'] ?? i['item_name'] ?? 'Unknown';
      final qty = i['quantity']?.toString() ?? '1';
      final unit = i['unit'] ?? '';
      final category = i['category'] ?? '';

      try {
        await _api.addInventoryItem(
          userId: userId,
          ingredientName: canonicalName,
          category: category.isNotEmpty ? category : 'Pantry',
          quantity: double.tryParse(qty) ?? 1.0,
          unit: unit.isEmpty ? 'pcs' : unit,
          location: 'Fridge',
          expiryDate: i['expiry_date'],
        );
        added++;
        if (mounted) setState(() => _addedIndices.add(idx));
      } catch (e) {
        debugPrint('Bulk add error for $canonicalName: $e');
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)?.addedNItemsToShelf(added.toString()) ?? 'Added $added items to shelf!'),
        backgroundColor: Theme.of(context).colorScheme.tertiary,
      ),
    );
  }

  Widget _sectionHeader(String title, String subtitle, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(title,
              style: TextStyle(
                  color: color, fontSize: 15, fontWeight: FontWeight.w700)),
          Spacer(),
          Text(subtitle,
              style: TextStyle(
                  color: color.withValues(alpha: 0.6), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _resultTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onConfirm,
    Widget? trailing,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14)),
        subtitle: Text(subtitle,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12)),
        trailing: trailing ?? (onConfirm != null
            ? IconButton(
                icon: Icon(Icons.check, color: Theme.of(context).colorScheme.tertiary),
                onPressed: onConfirm,
              )
            : null),
      ),
    );
  }

  // ── Manual Entry Form ────────────────────────────────────────────

  void _showManualEntryForm({String? prefillName, String? prefillCategory}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ManualEntryBottomSheet(
        prefillName: prefillName,
        prefillCategory: prefillCategory,
      ),
    );
  }

  // ── Barcode Scanner ─────────────────────────────────────────────

  Future<void> _openBarcodeScanner() async {
    final barcode = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(AppLocalizations.of(context)?.auto_enterBarcode ?? 'Enter Barcode',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'e.g., 8801234567890',
              hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context)?.auto_cancel ?? 'Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
              ),
              child: Text(AppLocalizations.of(context)?.auto_lookUp ?? 'Look Up'),
            ),
          ],
        );
      },
    );

    if (barcode == null || barcode.isEmpty) return;

    setState(() {
      _scanning = true;
      _error = null;
    });

    try {
      final result = await _api.lookupBarcode(barcode);
      if (!mounted) return;

      setState(() => _scanning = false);

      if (result != null && result['product'] != null) {
        final product = result['product'] as Map<String, dynamic>;
        _showManualEntryForm(
          prefillName: product['product_name'] as String? ?? barcode,
          prefillCategory: product['categories'] as String?,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.noProductFoundForBarcode(barcode) ?? 'No product found for barcode $barcode'),
            backgroundColor: Colors.orange.shade800,
          ),
        );
        _showManualEntryForm(prefillName: barcode);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _scanning = false;
        _error = 'Barcode lookup failed: $e';
      });
    }
  }

  Widget _buildTutorialScanPrompt() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🔍',
                style: TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 16),
              Text(
                'Ingredient Scanning',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'In Plately, you can scan a supermarket receipt, snap a photo of food in your fridge, or scan barcodes to log ingredients.\n\nFor this interactive tour, we will simulate loading 5 key ingredients for a special Chicken Stir-fry without writing any data to the database.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              // List of mock ingredients to load
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    _TutorialIngredientRow(emoji: '🍗', name: 'Chicken Breast (500g)'),
                    _TutorialIngredientRow(emoji: '🥦', name: 'Broccoli (1 head)'),
                    _TutorialIngredientRow(emoji: '🫗', name: 'Soy Sauce (150ml)'),
                    _TutorialIngredientRow(emoji: '🧄', name: 'Garlic (3 cloves)'),
                    _TutorialIngredientRow(emoji: '🫒', name: 'Sesame Oil (50ml)'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () {
                    ref.read(tutorialControllerProvider.notifier).setStep(TutorialState.shelfAdded);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Load Mock Ingredients 🛒',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManualEntryBottomSheet extends StatefulWidget {
  final String? prefillName;
  final String? prefillCategory;
  const _ManualEntryBottomSheet({this.prefillName, this.prefillCategory});

  @override
  State<_ManualEntryBottomSheet> createState() => _ManualEntryBottomSheetState();
}

class _ManualEntryBottomSheetState extends State<_ManualEntryBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  String _ingredientName = '';
  double _quantity = 1.0;
  String _unit = 'pcs';
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 7));
  
  // Category to bind the state of the dropdown
  String _category = 'Produce';
  String _location = 'Fridge';
  
  final List<String> _categories = [
    'Produce', 'Vegetable', 'Fruit', 'Meat', 'Poultry', 'Seafood',
    'Dairy', 'Milk', 'Cheese', 'Yogurt', 'Eggs',
    'Bakery', 'Bread', 'Grain', 'Pasta',
    'Pantry', 'Canned', 'Frozen',
    'Beverage', 'Juice', 'Snack',
    'Condiment', 'Spice', 'Oil', 'Sauce',
    'Nuts', 'Legumes', 'Tofu', 'Protein',
  ];

  final List<String> _units = [
    // Count
    'pcs', 'pack', 'bunch',
    // Mass
    'g', 'kg', 'oz', 'lb',
    // Volume
    'ml', 'L', 'cup', 'tbsp', 'tsp'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.prefillName != null) {
      _ingredientName = widget.prefillName!;
    }
    if (widget.prefillCategory != null && _categories.contains(widget.prefillCategory)) {
      _category = widget.prefillCategory!;
    }
    _updateExpiryByCategory(_category);
  }

  void _updateExpiryByCategory(String cat) {
    final lc = cat.toLowerCase();
    int days;
    switch (lc) {
      case 'produce':
      case 'vegetable': days = 7; break;
      case 'fruit': days = 5; break;
      case 'meat':
      case 'poultry': days = 3; break;
      case 'seafood': days = 2; break;
      case 'dairy': days = 10; break;
      case 'milk': days = 7; break;
      case 'cheese': days = 30; break;
      case 'yogurt': days = 14; break;
      case 'eggs': days = 21; break;
      case 'bakery':
      case 'bread': days = 5; break;
      case 'grain':
      case 'pasta': days = 365; break;
      case 'pantry':
      case 'canned': days = 365; break;
      case 'frozen': days = 90; break;
      case 'beverage':
      case 'juice': days = 30; break;
      case 'snack': days = 60; break;
      case 'condiment':
      case 'sauce': days = 180; break;
      case 'spice': days = 730; break; // 2 years
      case 'oil': days = 365; break;
      case 'nuts': days = 180; break;
      case 'legumes': days = 365; break;
      case 'tofu': days = 7; break;
      case 'protein': days = 3; break;
      default: days = 14;
    }
    setState(() {
      _expiryDate = DateTime.now().add(Duration(days: days));
    });
  }

  bool _submitting = false;

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_submitting) return; // Prevent double-taps
      setState(() => _submitting = true);

      // Insert via backend API (bypasses RLS)
      final api = ApiService();
      try {
        final userId = currentUserId();

        await api.addInventoryItem(
          userId: userId,
          ingredientName: _ingredientName,
          category: _category,
          quantity: _quantity,
          unit: _unit,
          location: _location.toLowerCase(),
          expiryDate: _expiryDate.toIso8601String(),
        );

        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.addedItemToShelf(_ingredientName) ?? 'Added $_ingredientName to shelf!'),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
          ),
        );
      } catch (e) {
        debugPrint('[ManualEntry] Failed to add item: $e');
        if (!mounted) return;
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.errorX('Failed to add item. Check your connection.') ?? 'Failed to add item. Check your connection.'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
      } finally {
        api.dispose();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Handle keyboard pushing up the sheet
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: bottomInset > 0 ? bottomInset + 24 : 48,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            Text(
              AppLocalizations.of(context)?.manual_addIngredient ?? 'Add Ingredient',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 20),

            // Location picker
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'Fridge', label: Text(AppLocalizations.of(context)?.auto_fridge ?? 'Fridge'), icon: Icon(Icons.kitchen, size: 16)),
                ButtonSegment(value: 'Freezer', label: Text(AppLocalizations.of(context)?.auto_freezer ?? 'Freezer'), icon: Icon(Icons.ac_unit, size: 16)),
                ButtonSegment(value: 'Pantry', label: Text(AppLocalizations.of(context)?.auto_pantry ?? 'Pantry'), icon: Icon(Icons.shelves, size: 16)),
              ],
              selected: {_location},
              onSelectionChanged: (v) => setState(() => _location = v.first),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Theme.of(context).colorScheme.primary.withValues(alpha: 0.15);
                  }
                  return Theme.of(context).colorScheme.surfaceContainerHighest;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Theme.of(context).colorScheme.primary;
                  }
                  return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4);
                }),
                side: WidgetStateProperty.all(
                  BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
                ),
              ),
            ),
            SizedBox(height: 16),

            // Autocomplete Field
            LayoutBuilder(
              builder: (context, constraints) => Autocomplete<Map<String, dynamic>>(
                displayStringForOption: (opt) {
                  // Show localized name based on current locale
                  final lang = Localizations.localeOf(context).languageCode;
                  final locale = Localizations.localeOf(context);
                  final isUzCyrl = lang == 'uz' && locale.scriptCode == 'Cyrl';
                  if (isUzCyrl) return opt['display_name_uz_cyrl'] ?? opt['display_name_uz'] ?? opt['display_name_en'] ?? '';
                  switch (lang) {
                    case 'ko': return opt['display_name_ko'] ?? opt['display_name_en'] ?? '';
                    case 'uz': return opt['display_name_uz'] ?? opt['display_name_en'] ?? '';
                    case 'ru': return opt['display_name_ru'] ?? opt['display_name_en'] ?? '';
                    default: return opt['display_name_en'] ?? '';
                  }
                },
                optionsBuilder: (TextEditingValue textEditingValue) async {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<Map<String, dynamic>>.empty();
                  }
                  try {
                    final q = textEditingValue.text;
                    final res = await Supabase.instance.client
                        .from('ingredients')
                        .select('*')
                        .or('display_name_en.ilike.%$q%,display_name_ko.ilike.%$q%,display_name_uz.ilike.%$q%,display_name_uz_cyrl.ilike.%$q%,display_name_ru.ilike.%$q%,canonical_name.ilike.%$q%')
                        .limit(5);
                    return (res as List).map((e) => e as Map<String, dynamic>);
                  } catch (e) {
                    return const Iterable<Map<String, dynamic>>.empty();
                  }
                },
                onSelected: (Map<String, dynamic> selection) {
                  setState(() {
                    // Store English name for backend, but show localized
                    _ingredientName = selection['display_name_en'] ?? '';
                    if (selection['category'] != null && _categories.contains(selection['category'])) {
                      _category = selection['category'];
                    }
                    if (selection['default_unit'] != null && _units.contains(selection['default_unit'])) {
                      _unit = selection['default_unit'];
                    }
                    // Use per-ingredient shelf life if available
                    final shelfDays = selection['sealed_shelf_life_days'];
                    if (shelfDays != null && shelfDays is int && shelfDays > 0) {
                      _expiryDate = DateTime.now().add(Duration(days: shelfDays));
                    } else {
                      _updateExpiryByCategory(_category);
                    }
                    // Auto-set location from storage zone
                    final zone = selection['storage_zone']?.toString().toLowerCase() ?? '';
                    if (zone == 'fridge') {
                      _location = 'Fridge';
                    } else if (zone == 'freezer') _location = 'Freezer';
                    else if (zone == 'pantry') _location = 'Pantry';
                  });
                },
                fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                  // Ensure ingredient name is captured if user types without selecting
                  textEditingController.addListener(() {
                    _ingredientName = textEditingController.text;
                  });
                    return TextFormField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)?.manual_ingredientName ?? 'Ingredient Name',
                      hintText: AppLocalizations.of(context)?.manual_ingredientHint ?? 'e.g. Apples, Bread, Milk',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: Icon(Icons.search),
                    ),
                    validator: (v) => v == null || v.isEmpty ? (AppLocalizations.of(context)?.manual_required ?? 'Required') : null,
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(12),
                      color: Theme.of(context).colorScheme.surface,
                      child: Container(
                        width: constraints.maxWidth,
                        constraints: const BoxConstraints(maxHeight: 240),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final option = options.elementAt(index);
                            final cat = option['category'] as String? ?? '';
                            final lang = Localizations.localeOf(context).languageCode;
                            final locale = Localizations.localeOf(context);
                            final isUzCyrl = lang == 'uz' && locale.scriptCode == 'Cyrl';
                            // Pick localized display name
                            String displayName;
                            if (isUzCyrl) {
                              displayName = option['display_name_uz_cyrl'] ?? option['display_name_uz'] ?? option['display_name_en'] ?? '';
                            } else {
                              switch (lang) {
                                case 'ko': displayName = option['display_name_ko'] ?? option['display_name_en'] ?? ''; break;
                                case 'uz': displayName = option['display_name_uz'] ?? option['display_name_en'] ?? ''; break;
                                case 'ru': displayName = option['display_name_ru'] ?? option['display_name_en'] ?? ''; break;
                                default: displayName = option['display_name_en'] ?? '';
                              }
                            }
                            final translatedCat = L10nHelper.translateCategory(cat, Localizations.localeOf(context));
                            return ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  categoryImageUrl(cat),
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    width: 40, height: 40,
                                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    child: Center(child: Text(categoryEmoji(cat), style: TextStyle(fontSize: 20))),
                                  ),
                                ),
                              ),
                              title: Text(displayName, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600)),
                              subtitle: Text(translatedCat, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12)),
                              onTap: () => onSelected(option),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16),

            // Category Dropdown
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)?.manual_category ?? 'Category',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.category),
              ),
              items: _categories.map((c) {
                return DropdownMenuItem(value: c, child: Text(L10nHelper.translateCategory(c, Localizations.localeOf(context))));
              }).toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    _category = v;
                    _updateExpiryByCategory(v);
                  });
                }
              },
            ),
            SizedBox(height: 16),

            // Quantity & Unit Row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: '1',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)?.manual_qty ?? 'Qty',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSaved: (v) => _quantity = double.tryParse(v!) ?? 1.0,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    initialValue: _unit,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)?.manual_metricType ?? 'Metric Type',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    onChanged: (v) => setState(() => _unit = v!),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Expiry Date Picker (Mocked Action)
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _expiryDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 730)),
                );
                if (date != null) setState(() => _expiryDate = date);
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)?.manual_estimatedExpiry ?? 'Estimated Expiry',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  '${_expiryDate.month}/${_expiryDate.day}/${_expiryDate.year}',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            SizedBox(height: 32),

            // Submit
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(AppLocalizations.of(context)?.auto_addToShelf ?? 'Add to Shelf', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mode Tab Widget ─────────────────────────────────────────────────

class _ModeTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _ModeTab({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  color: isActive ? activeColor : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), size: 20),
              SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      color: isActive ? activeColor : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Calorie Scan Tab (photo-based) ───────────────────────────────

class _CalorieScanTab extends StatefulWidget {
  const _CalorieScanTab();
  @override
  State<_CalorieScanTab> createState() => _CalorieScanTabState();
}

class _CalorieScanTabState extends State<_CalorieScanTab> {
  final ImagePicker _picker = ImagePicker();
  final ApiService _api = ApiService();
  bool _analyzing = false;
  bool _logging = false;
  Map<String, dynamic>? _result;
  Uint8List? _imageBytes;
  String _mealType = 'snack';
  String? _errorMessage;

  final List<String> _mealTypes = ['breakfast', 'lunch', 'dinner', 'snack'];
  final Map<String, String> _mealEmoji = {
    'breakfast': '🌅', 'lunch': '☀️', 'dinner': '🌙', 'snack': '🍿',
  };

  Future<void> _captureAndAnalyze(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 85,
        requestFullMetadata: false);
      if (image == null) return;

      final bytes = await image.readAsBytes();
      setState(() { _analyzing = true; _result = null; _imageBytes = bytes; _errorMessage = null; });

      final result = await _api.analyzeCaloriesImage(bytes, image.name);

      if (!mounted) return;

      // Handle no food detected
      if (result['status'] == 'no_food_detected' ||
          ((result['items'] as List?)?.isEmpty ?? true)) {
        setState(() {
          _analyzing = false;
          _errorMessage = AppLocalizations.of(context)?.recognitionFailed ??
              'No food items detected. Try a clearer photo with food visible.';
          _result = null;
        });
        return;
      }

      setState(() { _result = result; _analyzing = false; });
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final msg = e.toString().contains('warming up') || e.toString().contains('Timeout')
          ? (l10n?.recognitionFailed ?? 'Server is warming up from sleep. Please try again in a few seconds!')
          : (l10n?.recognitionFailed ?? 'Could not analyze photo. Please try a clearer photo with food visible.');
      setState(() {
        _analyzing = false;
        _errorMessage = msg;
      });
    }
  }

  Future<void> _logMeal() async {
    if (_result == null) return;
    setState(() => _logging = true);
    try {
      final userId = currentUserId();
      final itemsList = _result!['items'] as List?;
      final List<Map<String, dynamic>> items = [];

      if (itemsList != null && itemsList.isNotEmpty) {
        items.addAll(itemsList.map<Map<String, dynamic>>((item) => {
          'name': item['name'] ?? '',
          'calories': item['estimated_calories'] ?? 0,
          'protein_g': item['protein_g'] ?? 0,
          'carbs_g': item['carbs_g'] ?? 0,
          'fat_g': item['fat_g'] ?? 0,
        }));
      } else {
        items.add({
          'name': _result!['meal_name'] ?? 'Scanned Meal',
          'calories': _result!['total_estimated_calories'] ?? 0,
          'protein_g': _result!['protein_g'] ?? 0,
          'carbs_g': _result!['carbs_g'] ?? 0,
          'fat_g': _result!['fat_g'] ?? 0,
        });
      }

      await _api.logNutrition(
        userId: userId, mealType: _mealType, foodItems: items);

      if (!mounted) return;
      setState(() => _logging = false);

      // Show success with option to view tracker
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text('Meal logged!')),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const NutritionTrackerPage()));
                },
                child: Text('VIEW', style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800,
                  decoration: TextDecoration.underline)),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );
      setState(() { _result = null; _imageBytes = null; });
    } catch (e) {
      if (!mounted) return;
      setState(() => _logging = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to log meal. Try again.'), backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating),
      );
    }
  }

  void _clearResults() {
    setState(() { _result = null; _imageBytes = null; _errorMessage = null; });
  }

  @override
  void dispose() { _api.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Image Preview / Placeholder ─────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                image: _imageBytes != null
                    ? DecorationImage(image: MemoryImage(_imageBytes!), fit: BoxFit.cover)
                    : null,
              ),
              child: _imageBytes == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_fire_department, size: 56, color: Colors.orange),
                        SizedBox(height: 12),
                        Text(AppLocalizations.of(context)?.auto_snapYourMeal ?? 'Snap Your Meal',
                          style: TextStyle(color: cs.onSurface, fontSize: 20, fontWeight: FontWeight.w700)),
                        SizedBox(height: 6),
                        Text(AppLocalizations.of(context)?.auto_takeAPhotoAndAiWillEstimateCalories ?? 'Take a photo and AI will estimate calories',
                          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 13)),
                      ],
                    )
                  : _analyzing
                      ? Center(
                          child: Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(16)),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: Colors.orange),
                                SizedBox(height: 12),
                                Text(AppLocalizations.of(context)?.analyzingYourFood ?? 'Analyzing food...', style: TextStyle(color: cs.onSurface, fontSize: 14, fontWeight: FontWeight.w600)),
                                SizedBox(height: 4),
                                Text(AppLocalizations.of(context)?.aiIsIdentifying ?? 'Identifying items & estimating calories', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 11)),
                              ],
                            ),
                          ),
                        )
                      : null,
            ),
          ),
          SizedBox(height: 16),

          // ── Camera / Gallery Buttons ────────────────────────────
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _analyzing ? null : () => _captureAndAnalyze(ImageSource.camera),
                    icon: Icon(Icons.camera_alt, size: 20),
                    label: Text(AppLocalizations.of(context)?.auto_camera ?? 'Camera', style: TextStyle(fontWeight: FontWeight.w600)),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _analyzing ? null : () => _captureAndAnalyze(ImageSource.gallery),
                    icon: Icon(Icons.photo_library, size: 20, color: Colors.orange),
                    label: Text(AppLocalizations.of(context)?.auto_gallery ?? 'Gallery', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.orange),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  ),
                ),
              ),
            ],
          ),

          // ── Error / No Food State ──────────────────────────────
          if (_errorMessage != null) ...[
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.15)),
              ),
              child: Column(
                children: [
                  Icon(Icons.no_food, size: 40, color: Colors.orange.withValues(alpha: 0.5)),
                  SizedBox(height: 12),
                  Text(_errorMessage!, textAlign: TextAlign.center,
                    style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6), fontSize: 14)),
                  SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _clearResults,
                    icon: Icon(Icons.refresh, size: 18, color: Colors.orange),
                    label: Text(AppLocalizations.of(context)?.auto_retry ?? AppLocalizations.of(context)?.retry ?? 'Try Again', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],

          // ── Results ────────────────────────────────────────────
          if (_result != null) ...[
            SizedBox(height: 20),

            // Plate name + serving weight info
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.restaurant, color: Colors.orange, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _result!['meal_name'] ?? 'Scanned Plate',
                          style: TextStyle(color: cs.onSurface, fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Estimated plate serving: ~${_result!['estimated_weight_g'] ?? 0}g',
                          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),

            // Total calories hero card with overall plate macros
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.withValues(alpha: 0.15), cs.surface],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Text('🔥 ${_result!['total_estimated_calories'] ?? 0}',
                    style: TextStyle(color: Colors.orange, fontSize: 36, fontWeight: FontWeight.w800)),
                  Text('estimated calories for whole plate',
                    style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54), fontSize: 13)),
                  SizedBox(height: 16),
                  // Overall plate macros
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _macroChip('Protein', _result!['protein_g'] ?? 0, Colors.blue),
                      SizedBox(width: 8),
                      _macroChip('Carbs', _result!['carbs_g'] ?? 0, Colors.amber.shade700),
                      SizedBox(width: 8),
                      _macroChip('Fat', _result!['fat_g'] ?? 0, Colors.red),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Component breakdown title
            if (((_result!['items'] as List?) ?? []).isNotEmpty) ...[
              Text(
                'Plate Components',
                style: TextStyle(color: cs.onSurface, fontSize: 14, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 8),
              ...((_result!['items'] as List?) ?? []).map((item) => Container(
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['name'] ?? '',
                            style: TextStyle(color: cs.onSurface, fontSize: 14, fontWeight: FontWeight.w600)),
                          Text('~${item['estimated_serving_g'] ?? item['serving_g'] ?? '?'}g portion',
                            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 11)),
                        ],
                      ),
                    ),
                    Text('${item['estimated_calories'] ?? '?'}',
                      style: TextStyle(color: Colors.orange, fontSize: 16, fontWeight: FontWeight.w800)),
                    Text(' cal', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.38), fontSize: 11)),
                  ],
                ),
              )),
              SizedBox(height: 16),
            ],

            // Meal type selector
            Row(
              children: [
                ..._mealTypes.map((type) => Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _mealType = type),
                    child: Container(
                      margin: EdgeInsets.only(right: 4),
                      padding: EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _mealType == type ? Colors.orange.withValues(alpha: 0.15) : cs.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _mealType == type ? Colors.orange.withValues(alpha: 0.4) : cs.onSurface.withValues(alpha: 0.06)),
                      ),
                      child: Column(
                        children: [
                          Text(_mealEmoji[type] ?? '🍽️', style: TextStyle(fontSize: 16)),
                          Text(type[0].toUpperCase() + type.substring(1),
                            style: TextStyle(
                              color: _mealType == type ? Colors.orange : cs.onSurface.withValues(alpha: 0.38),
                              fontSize: 10, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                )),
              ],
            ),

            SizedBox(height: 16),

            // Consume / Cancel options
            Row(
              children: [
                // Cancel option
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _logging ? null : _clearResults,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: cs.onSurface.withValues(alpha: 0.12)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      child: Text('Cancel', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6), fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                // Consume option
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _logging ? null : _logMeal,
                      icon: _logging
                          ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Icon(Icons.check_circle, size: 20),
                      label: Text(_logging ? 'Consuming...' : 'Consume', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.tertiary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _macroChip(String label, dynamic value, Color color) {
    final v = (value is int) ? value : (value as num?)?.round() ?? 0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: ${v}g',
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _TutorialIngredientRow extends StatelessWidget {
  final String emoji;
  final String name;

  const _TutorialIngredientRow({required this.emoji, required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Text(
            name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
