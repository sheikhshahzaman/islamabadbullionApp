import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../../models/shop_models.dart";
import "../../providers/shop_provider.dart";
import "scan_screen.dart";

/// Verify a product's authenticity by serial number (manual entry)
/// or by scanning its QR sticker.
class VerifyScreen extends StatefulWidget {
  /// When true, the QR scanner opens automatically on first build — used by
  /// the standalone "Scan QR Code" menu entry.
  final bool autoScan;
  const VerifyScreen({super.key, this.autoScan = false});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final _serialCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _busy = false;
  String? _error;
  VerifyResult? _result;

  @override
  void initState() {
    super.initState();
    if (widget.autoScan) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scanQr();
      });
    }
  }

  @override
  void dispose() {
    _serialCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify({String? token}) async {
    final serial = _serialCtrl.text.trim();
    if (token == null && serial.length < 5) {
      setState(() => _error = "Please enter the serial number printed on your item.");
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _result = null;
    });

    try {
      final api = context.read<ShopProvider>().api;
      final result = await api.verify(
        serial: token == null ? serial : null,
        token: token,
        customerName: _nameCtrl.text,
        customerPhone: _phoneCtrl.text,
      );
      setState(() => _result = result);
    } catch (e) {
      setState(() =>
          _error = "Verification failed. Please check your connection and try again.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _scanQr() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );
    if (code == null || !mounted) return;

    // QR stickers encode https://islamabadbullionexchange.com/v/{token}
    final uri = Uri.tryParse(code);
    final segments = uri?.pathSegments ?? const [];
    final vIndex = segments.indexOf("v");
    if (vIndex >= 0 && vIndex + 1 < segments.length) {
      await _verify(token: segments[vIndex + 1]);
    } else {
      // Not a URL — treat the scanned text as a serial number.
      _serialCtrl.text = code;
      await _verify();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Verify your item")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            "Every Islamabad Bullion Exchange item carries a unique serial "
            "number and QR sticker. Verify yours below.",
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _busy ? null : _scanQr,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text("Scan QR sticker"),
          ),
          const SizedBox(height: 12),
          Row(children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text("or enter manually", style: theme.textTheme.bodySmall),
            ),
            const Expanded(child: Divider()),
          ]),
          const SizedBox(height: 12),
          TextField(
            controller: _serialCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: "Serial number",
              hintText: "IBE-XXXX-XXXXXX",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: "Your name (optional)",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: "Your phone (optional)",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _busy ? null : () => _verify(),
            icon: _busy
                ? const SizedBox(
                    height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.verified_outlined),
            label: const Text("Verify"),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!,
                  style: TextStyle(color: theme.colorScheme.error)),
            ),
          if (_result != null) ...[
            const SizedBox(height: 16),
            _ResultCard(result: _result!),
          ],
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final VerifyResult result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!result.valid) {
      return Card(
        color: theme.colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: theme.colorScheme.onErrorContainer, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  result.message.isNotEmpty
                      ? result.message
                      : "Serial number not found in our records.",
                  style:
                      TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final item = result.item;
    String s(String key) => (item[key] ?? "").toString();

    final rows = <MapEntry<String, String>>[
      MapEntry("Serial", s("serial_number")),
      if (s("product_name").isNotEmpty) MapEntry("Product", s("product_name")),
      if (s("metal").isNotEmpty) MapEntry("Metal", s("metal")),
      if (s("karat").isNotEmpty) MapEntry("Karat", s("karat")),
      if (s("weight").isNotEmpty) MapEntry("Weight", s("weight")),
      if (s("status").isNotEmpty) MapEntry("Status", s("status")),
      if (item["scan_count"] != null)
        MapEntry("Times scanned", "${item["scan_count"]}"),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified, color: Colors.green.shade600, size: 32),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Genuine item — verified",
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: Colors.green.shade700),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 110,
                      child:
                          Text(row.key, style: theme.textTheme.bodySmall),
                    ),
                    Expanded(
                      child: Text(
                        row.value,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
