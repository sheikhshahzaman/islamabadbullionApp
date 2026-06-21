import "package:flutter/material.dart";
import "package:image_picker/image_picker.dart";
import "package:intl/intl.dart";
import "package:provider/provider.dart";

import "../../models/shop_models.dart";
import "../../providers/shop_provider.dart";
import "order_confirmation_screen.dart";

/// 3-step checkout matching the website:
///   1. customer details (creates the order server-side)
///   2. payment method + account details
///   3. proof screenshot upload
///
/// Reused by both the product cart and the Buy/Sell wizards: the caller
/// supplies [onCreateOrder] (which actually creates the order once the
/// customer's details are entered), an [estimatedTotal] to preview, and an
/// optional [onOrderComplete] hook (e.g. to clear the cart).
class CheckoutScreen extends StatefulWidget {
  final Future<CreatedOrder> Function(String name, String phone) onCreateOrder;
  final double estimatedTotal;
  final VoidCallback? onOrderComplete;

  const CheckoutScreen({
    super.key,
    required this.onCreateOrder,
    required this.estimatedTotal,
    this.onOrderComplete,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _money = NumberFormat("#,##0");
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();

  int _step = 0;
  bool _busy = false;
  String? _error;

  CreatedOrder? _created;
  String _method = "";
  XFile? _proof;

  static const _methods = <String, String>{
    "easypaisa": "EasyPaisa",
    "jazzcash": "JazzCash",
    "raast": "Raast",
    "bank_transfer": "Bank Transfer",
  };

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _referenceCtrl.dispose();
    super.dispose();
  }

  Future<void> _createOrder() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final created = await widget.onCreateOrder(
        _nameCtrl.text.trim(),
        _phoneCtrl.text.trim(),
      );
      setState(() {
        _created = created;
        _step = 1;
      });
    } catch (e) {
      setState(() => _error =
          "Could not create the order. Please check your connection and try again.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickProof() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file != null) setState(() => _proof = file);
  }

  Future<void> _submitPayment() async {
    final created = _created;
    final proof = _proof;
    if (created == null || proof == null || _method.isEmpty) return;

    final api = context.read<ShopProvider>().api;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final order = await api.submitPayment(
        orderNumber: created.order.orderNumber,
        method: _method,
        proofImagePath: proof.path,
        referenceNumber: _referenceCtrl.text,
      );
      widget.onOrderComplete?.call();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => OrderConfirmationScreen(order: order),
        ),
        (route) => route.isFirst,
      );
    } catch (e) {
      setState(() => _error = e
          .toString()
          .replaceFirst("Exception: ", "")
          .replaceFirst("Upload failed", "Upload failed —"));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Checkout")),
      body: Stepper(
        currentStep: _step,
        controlsBuilder: (_, _) => const SizedBox.shrink(),
        onStepTapped: null,
        steps: [
          Step(
            title: const Text("Your details"),
            isActive: _step >= 0,
            state: _step > 0 ? StepState.complete : StepState.indexed,
            content: _detailsStep(),
          ),
          Step(
            title: const Text("Payment method"),
            isActive: _step >= 1,
            state: _step > 1 ? StepState.complete : StepState.indexed,
            content: _methodStep(),
          ),
          Step(
            title: const Text("Upload payment proof"),
            isActive: _step >= 2,
            content: _proofStep(),
          ),
        ],
      ),
    );
  }

  Widget _errorBox() => _error == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        );

  Widget _detailsStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _errorBox(),
          Text(
              "Order total (estimated): Rs ${_money.format(widget.estimatedTotal)}"),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: "Full name",
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                (v == null || v.trim().length < 2) ? "Please enter your name" : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: "Phone number",
              hintText: "03XXXXXXXXX",
              border: OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.trim().length < 10)
                ? "Please enter a valid phone number"
                : null,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _createOrder,
            child: _busy
                ? const SizedBox(
                    height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text("Continue"),
          ),
        ],
      ),
    );
  }

  Widget _methodStep() {
    final created = _created;
    if (created == null) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _errorBox(),
        Text(
          "Order ${created.order.orderNumber} · Rs ${_money.format(created.order.totalAmount)}",
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        for (final entry in _methods.entries)
          RadioListTile<String>(
            value: entry.key,
            // ignore: deprecated_member_use
            groupValue: _method,
            // ignore: deprecated_member_use
            onChanged: (v) => setState(() => _method = v ?? ""),
            title: Text(entry.value),
            contentPadding: EdgeInsets.zero,
          ),
        if (_method.isNotEmpty) _accountDetails(created, theme),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _method.isEmpty ? null : () => setState(() => _step = 2),
          child: const Text("Continue"),
        ),
      ],
    );
  }

  Widget _accountDetails(CreatedOrder created, ThemeData theme) {
    final details = created.paymentAccounts.forMethod(_method);
    final entries =
        details.entries.where((e) => e.value.trim().isNotEmpty).toList();
    if (entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text("Account details will be shared on confirmation."),
      );
    }

    String label(String key) => switch (key) {
          "number" => "Account number",
          "name" => "Account name",
          "id" => "Raast ID",
          "bank_name" => "Bank",
          "account_title" => "Account title",
          "account_number" => "Account number",
          "iban" => "IBAN",
          _ => key,
        };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Send payment to:", style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            for (final e in entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 130,
                      child:
                          Text(label(e.key), style: theme.textTheme.bodySmall),
                    ),
                    Expanded(
                      child: SelectableText(
                        e.value,
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

  Widget _proofStep() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _errorBox(),
        const Text(
          "After sending the payment, upload a screenshot of the "
          "transaction receipt so our team can verify it.",
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _busy ? null : _pickProof,
          icon: const Icon(Icons.image_outlined),
          label: Text(_proof == null ? "Choose screenshot" : "Change screenshot"),
        ),
        if (_proof != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _proof!.name,
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        const SizedBox(height: 12),
        TextField(
          controller: _referenceCtrl,
          decoration: const InputDecoration(
            labelText: "Transaction reference (optional)",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: (_proof == null || _busy) ? null : _submitPayment,
          child: _busy
              ? const SizedBox(
                  height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text("Submit order"),
        ),
      ],
    );
  }
}
