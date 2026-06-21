import "package:flutter/material.dart";
import "package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../services/api_client.dart";
import "../services/pages_api.dart";

/// Renders an admin-managed page (About / Disclaimer / Privacy / Terms) from
/// the Laravel backend (GET /api/pages/{slug}). Editing the page in the website
/// admin (Filament → Pages) updates what the app shows on the next open.
///
/// The last successfully fetched HTML is cached locally so the page still
/// renders offline.
class LegalPageScreen extends StatefulWidget {
  final String slug;
  final String title; // already localized by the caller

  const LegalPageScreen({
    super.key,
    required this.slug,
    required this.title,
  });

  @override
  State<LegalPageScreen> createState() => _LegalPageScreenState();
}

class _LegalPageScreenState extends State<LegalPageScreen> {
  static const Color _bg = Color(0xFF1A5249);
  static const Color _card = Color(0xFF0A3C30);
  static const Color _accent = Color(0xFFdfa273);

  final PagesApi _api = PagesApi(ApiClient());

  String? _html;
  bool _loading = true;
  String? _error;

  String get _cacheKey => "page_html_${widget.slug}";

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached != null && cached.trim().isNotEmpty && mounted) {
        setState(() {
          _html = cached;
          _loading = false;
        });
      }
    } catch (_) {}
    await _fetch();
  }

  Future<void> _fetch() async {
    if (_html == null && mounted) setState(() => _loading = true);
    try {
      final page = await _api.fetch(widget.slug);
      if (!mounted) return;
      setState(() {
        _html = page.bodyHtml;
        _loading = false;
        _error = null;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, page.bodyHtml);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_html == null || _html!.trim().isEmpty) {
          _error =
              "Couldn't load this page. Please check your connection and try again.";
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    if (_loading && _html == null) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_accent),
        ),
      );
    }

    if (_error != null && (_html == null || _html!.trim().isEmpty)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, color: _accent, size: 44),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, height: 1.4),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.black,
                ),
                onPressed: _fetch,
                icon: const Icon(Icons.refresh),
                label: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      backgroundColor: _bg,
      color: Colors.white,
      onRefresh: _fetch,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _accent.withValues(alpha: 0.22)),
            ),
            child: HtmlWidget(
              _html ?? "",
              textStyle: const TextStyle(
                color: Colors.white,
                height: 1.5,
                fontSize: 15,
              ),
              customStylesBuilder: (element) {
                switch (element.localName) {
                  case "h1":
                  case "h2":
                  case "h3":
                  case "h4":
                    return {
                      "color": "#dfa273",
                      "margin-top": "14px",
                      "margin-bottom": "6px",
                    };
                  case "a":
                    return {"color": "#dfa273"};
                  default:
                    return null;
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
