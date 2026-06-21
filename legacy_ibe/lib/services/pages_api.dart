import "../config.dart";
import "api_client.dart";

/// A single admin-managed page (About, Disclaimer, Privacy, Terms …).
class PageContent {
  final String slug;
  final String title;
  final String bodyHtml;

  PageContent({
    required this.slug,
    required this.title,
    required this.bodyHtml,
  });

  factory PageContent.fromJson(Map<String, dynamic> json) => PageContent(
        slug: (json["slug"] ?? "").toString(),
        title: (json["title"] ?? "").toString(),
        bodyHtml: (json["body"] ?? "").toString(),
      );
}

/// Fetches admin-managed pages (GET /api/pages/{slug}).
class PagesApi {
  final ApiClient _client;
  PagesApi(this._client);

  Future<PageContent> fetch(String slug) async {
    final json = await _client.getJson(
      Uri.parse("${AppConfig.apiBase}/pages/$slug"),
    );
    final page = (json["page"] is Map)
        ? Map<String, dynamic>.from(json["page"] as Map)
        : <String, dynamic>{};
    return PageContent.fromJson(page);
  }
}
