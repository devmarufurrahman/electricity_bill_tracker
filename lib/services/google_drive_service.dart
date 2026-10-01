import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'auth_service.dart';
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

class GoogleDriveService extends GetxService {
  final AuthService _authService = Get.find<AuthService>();

  Future<drive.DriveApi?> _getDriveApi() async {
    try {
      final token = await _authService.getValidDriveAccessToken();
      if (token == null) return null;

      final headers = {'Authorization': 'Bearer $token'};
      final client = GoogleAuthClient(headers);

      return drive.DriveApi(client);
    } catch (e) {
      developer.log('Error getting Drive API: $e', name: 'GoogleDriveService');
      return null;
    }
  }

  Future<String?> getOrCreateFolder(String folderName) async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return null;

      final query =
          "mimeType='application/vnd.google-apps.folder' and name='$folderName' and trashed=false";
      final fileList = await driveApi.files.list(q: query, spaces: 'drive');

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        return fileList.files!.first.id;
      }

      // Folder doesn't exist, create it
      final folder = drive.File();
      folder.name = folderName;
      folder.mimeType = 'application/vnd.google-apps.folder';

      final createdFolder = await driveApi.files.create(folder);
      return createdFolder.id;
    } catch (e) {
      developer.log('Error getting/creating folder: $e', name: 'GoogleDriveService');
      return null;
    }
  }

  Future<String?> uploadPdfFile({
    required Uint8List pdfBytes,
    required String fileName,
    required String folderId,
  }) async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return null;

      final fileToUpload = drive.File();
      fileToUpload.name = fileName;
      fileToUpload.parents = [folderId];

      final media = drive.Media(Stream.value(pdfBytes.toList()), pdfBytes.length);

      final uploadedFile = await driveApi.files.create(
        fileToUpload,
        uploadMedia: media,
        $fields: 'id, webViewLink',
      );

      return uploadedFile.webViewLink ?? uploadedFile.id;
    } catch (e) {
      developer.log('Error uploading file: $e', name: 'GoogleDriveService');
      return null;
    }
  }
}
