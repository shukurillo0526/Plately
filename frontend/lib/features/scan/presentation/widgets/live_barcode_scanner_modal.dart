import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

enum ScannerMode { barcode, qrcode }

class LiveBarcodeScannerModal extends StatefulWidget {
  const LiveBarcodeScannerModal({super.key});

  @override
  State<LiveBarcodeScannerModal> createState() => _LiveBarcodeScannerModalState();
}

class _LiveBarcodeScannerModalState extends State<LiveBarcodeScannerModal> {
  late final MobileScannerController _controller;
  ScannerMode _currentMode = ScannerMode.barcode;
  bool _hasDetected = false;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasDetected) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final rawValue = barcode.rawValue?.trim();
      if (rawValue != null && rawValue.isNotEmpty) {
        _hasDetected = true;
        Navigator.of(context).pop(rawValue);
        break;
      }
    }
  }

  void _showManualInputDialog() {
    showDialog<String>(
      context: context,
      builder: (ctx) {
        final textController = TextEditingController();
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Qo\'lda kiritish / Enter Code',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          content: TextField(
            controller: textController,
            autofocus: true,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: _currentMode == ScannerMode.barcode
                  ? 'e.g., 8801234567890'
                  : 'QR code string...',
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
              child: const Text('Bekor qilish'),
            ),
            FilledButton(
              onPressed: () {
                final text = textController.text.trim();
                Navigator.pop(ctx);
                if (text.isNotEmpty && mounted) {
                  Navigator.of(context).pop(text);
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: const Text('Tasdiqlash'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isBarcode = _currentMode == ScannerMode.barcode;
    final frameWidth = size.width * 0.78;
    final frameHeight = isBarcode ? 160.0 : frameWidth;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Camera Scanner View ────────────────────────────────
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // ── Dark Dimmed Overlay + Viewfinder Frame ─────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: Stack(
              children: [
                // Top header bar
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 24),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        // Title
                        Text(
                          isBarcode ? 'Shtrix-kod skaneri' : 'QR kod skaneri',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        // Torch button
                        Container(
                          decoration: BoxDecoration(
                            color: _torchOn
                                ? Colors.amber.shade600
                                : Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              _torchOn ? Icons.flash_on : Icons.flash_off,
                              color: Colors.white,
                              size: 24,
                            ),
                            onPressed: () async {
                              await _controller.toggleTorch();
                              setState(() => _torchOn = !_torchOn);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Center viewfinder guide box
                Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    width: frameWidth,
                    height: frameHeight,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.amber.shade400,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.25),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Center laser scanning line
                        Center(
                          child: Container(
                            height: 2,
                            width: frameWidth * 0.8,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.amber.withValues(alpha: 0.0),
                                  Colors.amber.shade400,
                                  Colors.amber.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Instruction text
                Positioned(
                  bottom: 180,
                  left: 24,
                  right: 24,
                  child: Text(
                    isBarcode
                        ? 'Shtrix-kodni ramka ichiga yo\'naltiring'
                        : 'QR-kodni ramka ichiga yo\'naltiring',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      shadows: const [
                        Shadow(color: Colors.black, blurRadius: 4),
                      ],
                    ),
                  ),
                ),

                // ── Mode Toggle & Manual Entry Controls ────────────
                Positioned(
                  bottom: 40,
                  left: 20,
                  right: 20,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Toggle Segment: Barcode vs QR Square Code
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildToggleTab(
                              title: 'Shtrix-kod',
                              icon: Icons.view_week_rounded,
                              selected: isBarcode,
                              onTap: () {
                                if (!isBarcode) {
                                  setState(() => _currentMode = ScannerMode.barcode);
                                }
                              },
                            ),
                            _buildToggleTab(
                              title: 'QR-kod',
                              icon: Icons.qr_code_2_rounded,
                              selected: !isBarcode,
                              onTap: () {
                                if (isBarcode) {
                                  setState(() => _currentMode = ScannerMode.qrcode);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Manual entry button
                      TextButton.icon(
                        onPressed: _showManualInputDialog,
                        icon: const Icon(Icons.keyboard, color: Colors.white70, size: 20),
                        label: const Text(
                          'Qo\'lda kiritish',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.5),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTab({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.amber.shade600 : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.black : Colors.white70,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: selected ? Colors.black : Colors.white70,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
