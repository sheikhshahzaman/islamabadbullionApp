import "../models/silver_note_response.dart";
import "api_client.dart";

/// The silver-note feature existed only on the old PHP backend and was
/// already disabled there. The new Laravel backend has no equivalent, so
/// this returns an inactive note without any network call. The provider
/// and screens handle the inactive state exactly as before.
class SilverNoteApi {
  // ignore: avoid_unused_constructor_parameters
  SilverNoteApi(ApiClient client);

  Future<SilverNoteResponse> fetchNote() async {
    return SilverNoteResponse(
      success: true,
      noteEn: "",
      noteUr: "",
      isActive: false,
    );
  }
}
