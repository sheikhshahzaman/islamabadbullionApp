import "dart:async";

import "package:flutter/material.dart";
import "package:image_picker/image_picker.dart";
import "package:intl/intl.dart";
import "package:provider/provider.dart";

import "../../models/shop_models.dart";
import "../../providers/shop_provider.dart";
import "../../services/api_client.dart";
import "../../providers/site_config_provider.dart";
import "../../theme/brand.dart";
import "../../widgets/brand_kit.dart";
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
  final _addressCtrl = TextEditingController();

  int _step = 0;
  bool _busy = false;
  String? _error;
  Timer? _refreshTimer;

  CreatedOrder? _created;
  // Only bank transfer is offered, so it's pre-selected — nothing to choose.
  String _method = "bank_transfer";
  // Pickup is free and needs no address; delivery requires one.
  String _deliveryMethod = "pickup";
  XFile? _proof;

  /// Cash is offered when the customer collects, COD when we deliver. Only a
  /// bank transfer needs a payment screenshot.
  static const _methodLabels = <String, String>{
    "bank_transfer": "Bank Transfer",
    "cash": "Cash at Shop",
    "cod": "Cash on Delivery",
  };

  static const _methodBlurbs = <String, String>{
    "bank_transfer": "Transfer now, then upload the screenshot",
    "cash": "Pay in cash when you collect your order",
    "cod": "Pay in cash when your order is delivered",
  };

  List<String> get _availableMethods => _deliveryMethod == "delivery"
      ? const ["bank_transfer", "cod"]
      : const ["bank_transfer", "cash"];

  bool get _needsProof => _method == "bank_transfer";

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(
      // Rates only change about once a minute on the backend, so polling
      // every 5s just burned rate-limit allowance and battery.
      const Duration(seconds: 20),
      (_) => _refreshCreatedOrder(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _referenceCtrl.dispose();
    _addressCtrl.dispose();
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
      await _refreshCreatedOrder();
    } on RateLimitedException catch (e) {
      setState(() => _error = e.toString());
    } catch (e) {
      setState(
        () => _error =
            "Could not create the order. Please check your connection and try again.",
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refreshCreatedOrder() async {
    final created = _created;
    if (!mounted || created == null || _busy) return;

    try {
      final refreshed = await context.read<ShopProvider>().api.fetchOrder(
        created.order.orderNumber,
      );
      if (!mounted) return;
      setState(() {
        _created = CreatedOrder(
          order: refreshed.order,
          paymentAccounts: refreshed.paymentAccounts.accounts.isEmpty
              ? created.paymentAccounts
              : refreshed.paymentAccounts,
        );
      });
    } catch (_) {
      // Keep checkout usable if a background refresh fails.
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
    // Only a bank transfer needs the screenshot before we can submit.
    if (created == null || _method.isEmpty) return;
    if (_needsProof && proof == null) return;

    final api = context.read<ShopProvider>().api;
    await _refreshCreatedOrder();

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final order = await api.submitPayment(
        orderNumber: created.order.orderNumber,
        method: _method,
        proofImagePath: _needsProof ? proof?.path : null,
        deliveryMethod: _deliveryMethod,
        deliveryAddress: _deliveryMethod == "delivery"
            ? _addressCtrl.text
            : null,
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
    } on RateLimitedException catch (e) {
      setState(() => _error = e.toString());
    } catch (e) {
      setState(
        () => _error = e
            .toString()
            .replaceFirst("Exception: ", "")
            .replaceFirst("Upload failed", "Upload failed —"),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Brand.teal,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Checkout", style: Brand.display(24)),
      ),
      body: BrandBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              Brand.s16,
              Brand.s8,
              Brand.s16,
              Brand.s24,
            ),
            children: [
              _progressHeader(),
              const SizedBox(height: Brand.s16),
              switch (_step) {
                0 => _detailsStep(),
                1 => _methodStep(),
                _ => _proofStep(),
              },
            ],
          ),
        ),
      ),
    );
  }

  Widget _progressHeader() {
    // Cash and COD finish at the payment step, so there is no Proof stage to
    // show. Only a bank transfer has three.
    final labels = _needsProof
        ? const ["Details", "Payment", "Proof"]
        : const ["Details", "Payment"];

    return BrandCard(
      padding: const EdgeInsets.all(Brand.s12),
      radius: Brand.rMd,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            Expanded(child: _progressItem(i, labels[i])),
            if (i < labels.length - 1)
              Container(
                width: 18,
                height: 1,
                color: i < _step
                    ? Brand.gold
                    : Brand.textMuted.withValues(alpha: 0.18),
              ),
          ],
        ],
      ),
    );
  }

  Widget _progressItem(int index, String label) {
    final complete = index < _step;
    final active = index == _step;
    final color = complete || active
        ? Brand.gold
        : Brand.textMuted.withValues(alpha: 0.55);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: Brand.fast,
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: complete
                ? Brand.up.withValues(alpha: 0.16)
                : active
                ? Brand.gold.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.05),
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? Brand.gold : Colors.transparent,
              width: 2,
            ),
          ),
          child: Icon(
            complete ? Icons.check_rounded : Icons.circle,
            size: complete ? 19 : 9,
            color: complete ? Brand.up : color,
          ),
        ),
        const SizedBox(height: Brand.s8),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Brand.sans(
            11,
            color: active ? Brand.text : Brand.textMuted,
            weight: active ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _errorBox() => _error == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(Brand.s12),
            decoration: BoxDecoration(
              color: Brand.down.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(Brand.rSm),
              border: Border.all(color: Brand.down.withValues(alpha: 0.28)),
            ),
            child: Text(_error!, style: Brand.sans(12, color: Brand.down)),
          ),
        );

  Widget _detailsStep() {
    return BrandCard(
      gold: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _errorBox(),
            Text("Your details", style: Brand.display(22, color: Brand.gold)),
            const SizedBox(height: Brand.s4),
            Text(
              "Estimated total: Rs ${_money.format(widget.estimatedTotal)}",
              style: Brand.sans(13, color: Brand.textMuted),
            ),
            const SizedBox(height: Brand.s20),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              style: Brand.sans(15),
              decoration: _fieldDecoration(
                label: "Full name",
                icon: Icons.person_outline,
              ),
              validator: (v) => (v == null || v.trim().length < 2)
                  ? "Please enter your name"
                  : null,
            ),
            const SizedBox(height: Brand.s12),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              style: Brand.sans(15),
              decoration: _fieldDecoration(
                label: "Phone number",
                hint: "03XXXXXXXXX",
                icon: Icons.call_outlined,
              ),
              validator: (v) => (v == null || v.trim().length < 10)
                  ? "Please enter a valid phone number"
                  : null,
            ),
            const SizedBox(height: Brand.s20),
            _primaryButton(
              label: "Continue",
              icon: Icons.arrow_forward_rounded,
              onPressed: _busy ? null : _createOrder,
              busy: _busy,
            ),
          ],
        ),
      ),
    );
  }

  Widget _methodStep() {
    final created = _created;
    if (created == null) return const SizedBox.shrink();
    final deliveryCharge = context
        .watch<SiteConfigProvider>()
        .config
        .deliveryCharge;

    final addressFilled = _addressCtrl.text.trim().isNotEmpty;
    final canContinue =
        _method.isNotEmpty && (_deliveryMethod != "delivery" || addressFilled);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _errorBox(),
        BrandCard(
          gold: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Payment", style: Brand.display(22, color: Brand.gold)),
              const SizedBox(height: Brand.s12),
              _summaryRow("Order", created.order.orderNumber, mono: true),
              const SizedBox(height: Brand.s8),
              _summaryRow(
                "Items total",
                "Rs ${_money.format(created.order.totalAmount)}",
                strong: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: Brand.s12),
        BrandCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(
                "Pickup or delivery?",
                Icons.local_shipping_outlined,
              ),
              const SizedBox(height: Brand.s12),
              _choiceTile(
                selected: _deliveryMethod == "pickup",
                title: "Pickup from our shop",
                subtitle: "Free",
                icon: Icons.storefront_outlined,
                onTap: () => setState(() {
                  _deliveryMethod = "pickup";
                  if (!_availableMethods.contains(_method)) {
                    _method = "bank_transfer";
                  }
                }),
              ),
              const SizedBox(height: 10),
              _choiceTile(
                selected: _deliveryMethod == "delivery",
                title: "Delivery",
                subtitle: deliveryCharge > 0
                    ? "Rs ${_money.format(deliveryCharge)}"
                    : "Free Delivery",
                icon: Icons.delivery_dining_outlined,
                onTap: () => setState(() {
                  _deliveryMethod = "delivery";
                  if (!_availableMethods.contains(_method)) {
                    _method = "bank_transfer";
                  }
                }),
              ),
              if (_deliveryMethod == "delivery") ...[
                const SizedBox(height: Brand.s16),
                TextField(
                  controller: _addressCtrl,
                  maxLines: 3,
                  minLines: 3,
                  style: Brand.sans(15),
                  onChanged: (_) => setState(() {}),
                  decoration: _fieldDecoration(
                    label: "Delivery address",
                    hint: "House/flat, street, area, city",
                    icon: Icons.place_outlined,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: Brand.s12),
        BrandCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle("Payment method", Icons.account_balance_outlined),
              const SizedBox(height: Brand.s12),
              for (final method in _availableMethods)
                _choiceTile(
                  selected: _method == method,
                  title: _methodLabels[method] ?? method,
                  subtitle: _methodBlurbs[method] ?? "",
                  icon: method == "bank_transfer"
                      ? Icons.account_balance_wallet_outlined
                      : Icons.payments_outlined,
                  onTap: () => setState(() => _method = method),
                ),
            ],
          ),
        ),
        if (_method.isNotEmpty && _needsProof) ...[
          const SizedBox(height: Brand.s12),
          _accountDetails(created, deliveryCharge),
        ],
        const SizedBox(height: Brand.s16),
        Row(
          children: [
            Expanded(
              child: _secondaryButton(
                label: "Back",
                icon: Icons.arrow_back_rounded,
                onPressed: () => setState(() => _step = 0),
              ),
            ),
            const SizedBox(width: Brand.s12),
            Expanded(
              child: _primaryButton(
                label: _needsProof ? "Continue" : "Place order",
                icon: _needsProof
                    ? Icons.arrow_forward_rounded
                    : Icons.check_rounded,
                onPressed: !canContinue || _busy
                    ? null
                    : () {
                        if (_needsProof) {
                          setState(() => _step = 2);
                        } else {
                          _submitPayment();
                        }
                      },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _accountDetails(CreatedOrder created, double deliveryCharge) {
    final details = created.paymentAccounts.forMethod(_method);
    final entries = details.entries
        .where((e) => e.value.trim().isNotEmpty)
        .toList();

    final delivery = _deliveryMethod == "delivery" ? deliveryCharge : 0.0;
    final grandTotal = created.order.totalAmount + delivery;

    if (entries.isEmpty) {
      return BrandCard(
        child: Text(
          "Account details will be shared on confirmation.",
          style: Brand.sans(13, color: Brand.textMuted),
        ),
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

    return BrandCard(
      gold: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("Bank details", Icons.receipt_long_outlined),
          const SizedBox(height: Brand.s12),
          Container(
            padding: const EdgeInsets.all(Brand.s12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(Brand.rSm),
              border: Border.all(color: Brand.hairlineSoft),
            ),
            child: Column(
              children: [
                _amountLine("Items", created.order.totalAmount),
                if (delivery > 0) _amountLine("Delivery", delivery),
                Divider(color: Brand.hairlineSoft, height: Brand.s20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        "Amount to send",
                        style: Brand.sans(12, color: Brand.textMuted),
                      ),
                    ),
                    Text(
                      "Rs ${_money.format(grandTotal)}",
                      style: Brand.number(20, color: Brand.gold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (final e in entries) _bankDetailRow(label(e.key), e.value),
          const SizedBox(height: Brand.s8),
          Text(
            "After transfer, continue and upload the payment screenshot.",
            style: Brand.sans(12, color: Brand.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _proofStep() {
    return BrandCard(
      gold: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _errorBox(),
          Text("Upload proof", style: Brand.display(22, color: Brand.gold)),
          const SizedBox(height: Brand.s8),
          Text(
            "Upload the transaction screenshot so our team can verify your order.",
            style: Brand.sans(13, color: Brand.textMuted, height: 1.45),
          ),
          const SizedBox(height: Brand.s20),
          InkWell(
            onTap: _busy ? null : _pickProof,
            borderRadius: BorderRadius.circular(Brand.rMd),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Brand.s16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(Brand.rMd),
                border: Border.all(
                  color: _proof == null
                      ? Brand.hairline
                      : Brand.up.withValues(alpha: 0.45),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _proof == null
                        ? Icons.cloud_upload_outlined
                        : Icons.check_circle_outline,
                    color: _proof == null ? Brand.gold : Brand.up,
                    size: 34,
                  ),
                  const SizedBox(height: Brand.s8),
                  Text(
                    _proof == null
                        ? "Choose screenshot"
                        : "Screenshot selected",
                    style: Brand.sans(14, weight: FontWeight.w800),
                  ),
                  if (_proof != null) ...[
                    const SizedBox(height: Brand.s4),
                    Text(
                      _proof!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Brand.sans(12, color: Brand.textMuted),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: Brand.s16),
          TextField(
            controller: _referenceCtrl,
            style: Brand.sans(15),
            decoration: _fieldDecoration(
              label: "Transaction reference",
              hint: "Optional",
              icon: Icons.confirmation_number_outlined,
            ),
          ),
          const SizedBox(height: Brand.s20),
          Row(
            children: [
              Expanded(
                child: _secondaryButton(
                  label: "Back",
                  icon: Icons.arrow_back_rounded,
                  onPressed: () => setState(() => _step = 1),
                ),
              ),
              const SizedBox(width: Brand.s12),
              Expanded(
                child: _primaryButton(
                  label: "Submit",
                  icon: Icons.check_rounded,
                  onPressed: (_proof == null || _busy) ? null : _submitPayment,
                  busy: _busy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    String? hint,
    IconData? icon,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(Brand.rSm),
      borderSide: BorderSide(color: Brand.gold.withValues(alpha: 0.55)),
    );

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon, color: Brand.gold, size: 20),
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.12),
      labelStyle: Brand.sans(12, color: Brand.textMuted),
      hintStyle: Brand.sans(13, color: Brand.textMuted.withValues(alpha: 0.65)),
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: Brand.gold, width: 1.6),
      ),
      errorBorder: border.copyWith(
        borderSide: const BorderSide(color: Brand.down),
      ),
      focusedErrorBorder: border.copyWith(
        borderSide: const BorderSide(color: Brand.down, width: 1.6),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Brand.gold, size: 20),
        const SizedBox(width: Brand.s8),
        Expanded(
          child: Text(title, style: Brand.sans(15, weight: FontWeight.w800)),
        ),
      ],
    );
  }

  Widget _choiceTile({
    required bool selected,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Brand.rMd),
      child: AnimatedContainer(
        duration: Brand.fast,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? Brand.gold.withValues(alpha: 0.14)
              : Colors.black.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(Brand.rMd),
          border: Border.all(
            color: selected ? Brand.gold : Brand.hairlineSoft,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: selected
                    ? Brand.gold.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: selected ? Brand.gold : Brand.textMuted),
            ),
            const SizedBox(width: Brand.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Brand.sans(14, weight: FontWeight.w800)),
                  const SizedBox(height: Brand.s4),
                  Text(subtitle, style: Brand.sans(12, color: Brand.textMuted)),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? Brand.gold : Brand.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool strong = false,
    bool mono = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(label, style: Brand.sans(12, color: Brand.textMuted)),
        ),
        Expanded(
          child: SelectableText(
            value,
            textAlign: TextAlign.right,
            style: Brand.sans(
              strong ? 16 : 13,
              weight: strong ? FontWeight.w800 : FontWeight.w600,
              height: 1.35,
            ).copyWith(fontFamily: mono ? "monospace" : null),
          ),
        ),
      ],
    );
  }

  Widget _amountLine(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Brand.sans(13, color: Brand.textMuted)),
          ),
          Text(
            "Rs ${_money.format(amount)}",
            style: Brand.number(14, weight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _bankDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: Brand.label(10, color: Brand.gold)),
          const SizedBox(height: 6),
          SelectableText(
            value,
            style: Brand.sans(15, weight: FontWeight.w700, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    bool busy = false,
  }) {
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: Brand.gold,
        foregroundColor: const Color(0xFF1A1207),
        disabledBackgroundColor: Brand.gold.withValues(alpha: 0.24),
        disabledForegroundColor: Brand.textMuted.withValues(alpha: 0.45),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Brand.rSm),
        ),
        textStyle: Brand.sans(14, weight: FontWeight.w900),
      ),
      icon: busy
          ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon),
      label: Text(label),
    );
  }

  Widget _secondaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Brand.text,
        side: BorderSide(color: Brand.gold.withValues(alpha: 0.55)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Brand.rSm),
        ),
        textStyle: Brand.sans(14, weight: FontWeight.w800),
      ),
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
