import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:intl/intl.dart";

import "../services/api_client.dart";
import "../services/buy_request_api.dart";
import "../theme/brand.dart";
import "../widgets/brand_kit.dart";

/// "Request to buy gold/silver".
///
/// Three stages: pick what you want and Calculate, review the total with
/// packaging and leave your details, then a thank-you confirmation. Nothing is
/// ordered or reserved — the shop calls the customer back.
///
/// Prices shown here always come from the server, so the app can never quote a
/// figure the backend would not honour.
class RequestToBuyScreen extends StatefulWidget {
  const RequestToBuyScreen({super.key});

  @override
  State<RequestToBuyScreen> createState() => _RequestToBuyScreenState();
}

enum _Stage { select, details, done }

class _RequestToBuyScreenState extends State<RequestToBuyScreen> {
  final _api = BuyRequestApi(ApiClient());
  final _money = NumberFormat("#,##0.##");

  final _weightCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _detailsFormKey = GlobalKey<FormState>();

  _Stage _stage = _Stage.select;

  BuyRequestOptions? _options;
  bool _loadingOptions = true;
  String? _loadError;

  String _metal = "gold";
  String _category = "bar";
  int? _productId;
  String _weightUnit = "gram";

  BuyRequestQuote? _quote;
  SubmittedBuyRequest? _submitted;

  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _api.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    setState(() {
      _loadingOptions = true;
      _loadError = null;
    });

    try {
      final options = await _api.fetchOptions();
      if (!mounted) return;
      setState(() {
        _options = options;
        _loadingOptions = false;
        _syncCategoryWithMetal();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingOptions = false;
        _loadError = e is RateLimitedException
            ? e.toString()
            : "Could not load the options. Please check your connection.";
      });
    }
  }

  List<String> get _categories =>
      _options?.categoriesFor(_metal) ?? const ["bar"];

  List<BuyRequestSize> get _sizes =>
      _options?.sizesFor(_metal) ?? const <BuyRequestSize>[];

  bool get _isRawa => _category == "rawa";

  /// Rawa is gold only, so switching to silver has to drop it.
  void _syncCategoryWithMetal() {
    if (!_categories.contains(_category)) {
      _category = _categories.first;
    }
    if (!_isRawa && !_sizes.any((s) => s.productId == _productId)) {
      _productId = null;
    }
  }

  double? get _weight {
    final value = double.tryParse(_weightCtrl.text.trim());
    return (value == null || value <= 0) ? null : value;
  }

  bool get _canCalculate =>
      _isRawa ? _weight != null : _productId != null;

  String get _selectionLabel {
    if (_isRawa) {
      final unit = _options?.rawaUnits[_weightUnit] ?? _weightUnit;
      return "${_weightCtrl.text.trim()} $unit Rawa";
    }
    final size = _sizes.where((s) => s.productId == _productId).firstOrNull;
    return size == null ? "" : "${size.label} - ${size.name}";
  }

  Future<void> _calculate() async {
    if (!_canCalculate || _busy) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final quote = await _api.quote(
        metal: _metal,
        category: _category,
        productId: _isRawa ? null : _productId,
        weightValue: _isRawa ? _weight : null,
        weightUnit: _isRawa ? _weightUnit : null,
      );
      if (!mounted) return;
      setState(() {
        _quote = quote;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _readableError(e);
      });
    }
  }

  Future<void> _submit() async {
    if (!(_detailsFormKey.currentState?.validate() ?? false) || _busy) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final submitted = await _api.submit(
        metal: _metal,
        category: _category,
        productId: _isRawa ? null : _productId,
        weightValue: _isRawa ? _weight : null,
        weightUnit: _isRawa ? _weightUnit : null,
        customerName: _nameCtrl.text.trim(),
        customerPhone: _phoneCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _submitted = submitted;
        _stage = _Stage.done;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _readableError(e);
      });
    }
  }

  String _readableError(Object e) {
    if (e is RateLimitedException) return e.toString();
    final text = e.toString();
    // Surface the server's own explanation when it sent one.
    final match = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(text);
    if (match != null) return match.group(1)!;
    return "Something went wrong. Please try again.";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Brand.teal,
      appBar: AppBar(
        backgroundColor: Brand.teal,
        elevation: 0,
        title: Text(
          "Request to Buy Gold/Silver",
          style: Brand.display(19, color: Brand.gold),
        ),
      ),
      body: SafeArea(
        child: _loadingOptions
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
                ? _loadErrorView()
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(Brand.s16),
                    child: switch (_stage) {
                      _Stage.select => _selectStage(),
                      _Stage.details => _detailsStage(),
                      _Stage.done => _doneStage(),
                    },
                  ),
      ),
    );
  }

  Widget _loadErrorView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(Brand.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, color: Brand.gold, size: 40),
              const SizedBox(height: Brand.s12),
              Text(
                _loadError!,
                textAlign: TextAlign.center,
                style: Brand.sans(14, color: Brand.textMuted),
              ),
              const SizedBox(height: Brand.s16),
              FilledButton.icon(
                onPressed: _loadOptions,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text("Try again"),
                style: FilledButton.styleFrom(
                  backgroundColor: Brand.gold,
                  foregroundColor: Brand.teal,
                ),
              ),
            ],
          ),
        ),
      );

  // ---------------------------------------------------------------- stage 1

  Widget _selectStage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BrandCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _title("Metal"),
              const SizedBox(height: Brand.s12),
              Row(
                children: [
                  Expanded(child: _pill("Gold", "gold", _metal, _selectMetal)),
                  const SizedBox(width: Brand.s12),
                  Expanded(
                    child: _pill("Silver", "silver", _metal, _selectMetal),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: Brand.s12),
        BrandCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _title("Category"),
              const SizedBox(height: Brand.s12),
              Row(
                children: [
                  for (final category in _categories) ...[
                    Expanded(
                      child: _pill(
                        _options?.categoryLabels[category] ?? category,
                        category,
                        _category,
                        _selectCategory,
                      ),
                    ),
                    if (category != _categories.last)
                      const SizedBox(width: Brand.s12),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: Brand.s12),
        if (_isRawa) _rawaInput() else _sizeList(),
        if (_error != null) ...[
          const SizedBox(height: Brand.s12),
          _errorBanner(_error!),
        ],
        if (_quote != null) ...[
          const SizedBox(height: Brand.s12),
          _priceCard(_quote!, showPackaging: false),
        ],
        const SizedBox(height: Brand.s16),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _canCalculate && !_busy ? _calculate : null,
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.calculate_outlined),
                label: const Text("Calculate"),
                style: FilledButton.styleFrom(
                  backgroundColor: Brand.gold,
                  foregroundColor: Brand.teal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            if (_quote != null) ...[
              const SizedBox(width: Brand.s12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                            _stage = _Stage.details;
                            _error = null;
                          }),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text("Next"),
                  style: FilledButton.styleFrom(
                    backgroundColor: Brand.gold,
                    foregroundColor: Brand.teal,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  void _selectMetal(String value) {
    setState(() {
      _metal = value;
      _quote = null;
      _error = null;
      _syncCategoryWithMetal();
    });
  }

  void _selectCategory(String value) {
    setState(() {
      _category = value;
      _quote = null;
      _error = null;
      if (_isRawa) {
        _productId = null;
      } else {
        _weightCtrl.clear();
      }
    });
  }

  /// Bar sizes come straight from the products admin has published, without
  /// images — this is a rate enquiry, not the shop.
  Widget _sizeList() {
    if (_sizes.isEmpty) {
      return BrandCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title("Size"),
            const SizedBox(height: Brand.s12),
            Text(
              "No ${_metal == "gold" ? "gold" : "silver"} bar sizes have been added yet. Please contact us and we will help you directly.",
              style: Brand.sans(13, color: Brand.textMuted),
            ),
          ],
        ),
      );
    }

    return BrandCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title("Size"),
          const SizedBox(height: Brand.s8),
          for (final size in _sizes)
            _sizeTile(size, selected: size.productId == _productId),
        ],
      ),
    );
  }

  Widget _sizeTile(BuyRequestSize size, {required bool selected}) {
    return Padding(
      padding: const EdgeInsets.only(top: Brand.s8),
      child: InkWell(
        borderRadius: BorderRadius.circular(Brand.rSm),
        onTap: () => setState(() {
          _productId = size.productId;
          _quote = null;
          _error = null;
        }),
        child: Container(
          padding: const EdgeInsets.all(Brand.s12),
          decoration: BoxDecoration(
            color: selected
                ? Brand.gold.withValues(alpha: 0.14)
                : Colors.black.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(Brand.rSm),
            border: Border.all(
              color: selected ? Brand.gold : Brand.hairlineSoft,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? Brand.gold : Brand.textMuted,
                size: 20,
              ),
              const SizedBox(width: Brand.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      size.label,
                      style: Brand.sans(
                        14,
                        color: Colors.white,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (size.name.trim() != size.label) ...[
                      const SizedBox(height: 2),
                      Text(
                        size.name,
                        style: Brand.sans(11.5, color: Brand.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Rawa is loose gold, so the customer names a weight instead of a size.
  Widget _rawaInput() {
    return BrandCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title("Weight"),
          const SizedBox(height: Brand.s12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _weightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r"[0-9.]")),
                  ],
                  style: Brand.sans(15, color: Colors.white),
                  onChanged: (_) => setState(() {
                    _quote = null;
                    _error = null;
                  }),
                  decoration: InputDecoration(
                    labelText: "Enter weight",
                    labelStyle: Brand.sans(13, color: Brand.textMuted),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: Brand.s12),
              _unitDropdown(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _unitDropdown() {
    final units = _options?.rawaUnits ?? const {"gram": "Gram", "tola": "Tola"};

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Brand.s12),
      decoration: BoxDecoration(
        border: Border.all(color: Brand.hairline),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: units.containsKey(_weightUnit) ? _weightUnit : units.keys.first,
          dropdownColor: Brand.teal,
          iconEnabledColor: Brand.gold,
          style: Brand.sans(14, color: Colors.white),
          items: [
            for (final entry in units.entries)
              DropdownMenuItem(value: entry.key, child: Text(entry.value)),
          ],
          onChanged: (value) => setState(() {
            if (value != null) _weightUnit = value;
            _quote = null;
            _error = null;
          }),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- stage 2

  Widget _detailsStage() {
    final quote = _quote!;

    return Form(
      key: _detailsFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _priceCard(quote, showPackaging: true),
          const SizedBox(height: Brand.s12),
          BrandCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _title("Your details"),
                const SizedBox(height: Brand.s12),
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  style: Brand.sans(15, color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Full name",
                    labelStyle: Brand.sans(13, color: Brand.textMuted),
                    prefixIcon: Icon(Icons.person_outline, color: Brand.gold),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().length < 2)
                      ? "Please enter your name"
                      : null,
                ),
                const SizedBox(height: Brand.s12),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: Brand.sans(15, color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Phone number",
                    labelStyle: Brand.sans(13, color: Brand.textMuted),
                    prefixIcon: Icon(Icons.phone_outlined, color: Brand.gold),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().length < 10)
                      ? "Please enter a valid phone number"
                      : null,
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: Brand.s12),
            _errorBanner(_error!),
          ],
          const SizedBox(height: Brand.s16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                            _stage = _Stage.select;
                            _error = null;
                          }),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text("Back"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Brand.gold,
                    side: BorderSide(color: Brand.hairline),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: Brand.s12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _busy ? null : _submit,
                  icon: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: const Text("Submit"),
                  style: FilledButton.styleFrom(
                    backgroundColor: Brand.gold,
                    foregroundColor: Brand.teal,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- stage 3

  Widget _doneStage() {
    final submitted = _submitted!;

    return Column(
      children: [
        const SizedBox(height: Brand.s32),
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Brand.gold.withValues(alpha: 0.14),
            border: Border.all(color: Brand.gold.withValues(alpha: 0.4)),
          ),
          child: Icon(Icons.check_rounded, size: 44, color: Brand.gold),
        ),
        const SizedBox(height: Brand.s20),
        Text("Thank you", style: Brand.display(26, color: Brand.gold)),
        const SizedBox(height: Brand.s12),
        Text(
          "We will contact you shortly on the number you provided.",
          textAlign: TextAlign.center,
          style: Brand.sans(14, color: Brand.textMuted),
        ),
        const SizedBox(height: Brand.s20),
        BrandCard(
          child: Column(
            children: [
              _row("Reference", submitted.reference),
              const SizedBox(height: Brand.s8),
              _row("Request", submitted.selection),
              const SizedBox(height: Brand.s8),
              _row("Estimated total", "Rs ${_money.format(submitted.totalAmount)}"),
            ],
          ),
        ),
        const SizedBox(height: Brand.s20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: Brand.gold,
              foregroundColor: Brand.teal,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text("Done"),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------ bits

  Widget _priceCard(BuyRequestQuote quote, {required bool showPackaging}) {
    final rateLabel = _isRawa
        ? "Rate per ${(_options?.rawaUnits[_weightUnit] ?? _weightUnit).toLowerCase()}"
        : "Price";

    return BrandCard(
      gold: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title(_selectionLabel.isEmpty ? "Estimate" : _selectionLabel),
          const SizedBox(height: Brand.s12),
          _row(rateLabel, "Rs ${_money.format(quote.unitPrice)}"),
          if (showPackaging) ...[
            const SizedBox(height: Brand.s8),
            _row(
              "Packaging",
              quote.packagingCharge > 0
                  ? "Rs ${_money.format(quote.packagingCharge)}"
                  : "Free",
            ),
          ],
          Divider(color: Brand.hairlineSoft, height: Brand.s24),
          Row(
            children: [
              Expanded(
                child: Text(
                  showPackaging ? "Estimated total" : "Estimated price",
                  style: Brand.sans(13, color: Brand.textMuted),
                ),
              ),
              Text(
                "Rs ${_money.format(quote.totalAmount)}",
                style: Brand.number(20, color: Brand.gold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _title(String text) =>
      Text(text, style: Brand.display(17, color: Brand.gold));

  Widget _row(String label, String value) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: Brand.sans(13, color: Brand.textMuted)),
          ),
          const SizedBox(width: Brand.s12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Brand.sans(
                13.5,
                color: Colors.white,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      );

  Widget _errorBanner(String message) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Brand.s12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(Brand.rSm),
          border: Border.all(color: Colors.red.withValues(alpha: 0.35)),
        ),
        child: Text(
          message,
          style: Brand.sans(13, color: const Color(0xFFFFB4A9)),
        ),
      );

  Widget _pill(
    String label,
    String value,
    String groupValue,
    void Function(String) onSelect,
  ) {
    final selected = value == groupValue;

    return InkWell(
      borderRadius: BorderRadius.circular(Brand.rSm),
      onTap: () => onSelect(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? Brand.gold.withValues(alpha: 0.16)
              : Colors.black.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(Brand.rSm),
          border: Border.all(
            color: selected ? Brand.gold : Brand.hairlineSoft,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          style: Brand.sans(
            14,
            color: selected ? Colors.white : Brand.textMuted,
          ).copyWith(fontWeight: selected ? FontWeight.w800 : FontWeight.w600),
        ),
      ),
    );
  }
}
