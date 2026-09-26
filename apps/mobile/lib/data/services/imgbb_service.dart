import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ImgbbSizeException implements Exception {
  final String message;
  ImgbbSizeException(this.message);

  @override
  String toString() => message;
}

class ImgbbUploadResult {
  final String url;
  final String displayUrl;
  final String? thumbUrl;
  final String? deleteUrl;

  const ImgbbUploadResult({
    required this.url,
    required this.displayUrl,
    this.thumbUrl,
    this.deleteUrl,
  });

  factory ImgbbUploadResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return ImgbbUploadResult(
      url: data['url'] as String,
      displayUrl: (data['display_url'] ?? data['url']) as String,
      thumbUrl: data['thumb'] != null ? data['thumb']['url'] as String? : null,
      deleteUrl: data['delete_url'] as String?,
    );
  }
}

class ImgbbService {
  static const String defaultApiKey = String.fromEnvironment(
    'IMGBB_API_KEY',
    defaultValue: '7961694b769c875edb3f7bccb84872d7',
  );
  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10MB limit

  final String apiKey;
  final http.Client _client;

  ImgbbService({
    String? apiKey,
    http.Client? client,
  })  : apiKey = apiKey ?? defaultApiKey,
        _client = client ?? http.Client();

  /// Upload image bytes with strict 10MB limit check
  Future<ImgbbUploadResult> uploadBytes(Uint8List bytes, {String? fileName}) async {
    if (bytes.lengthInBytes > maxFileSizeBytes) {
      final sizeMb = (bytes.lengthInBytes / (1024 * 1024)).toStringAsFixed(1);
      throw ImgbbSizeException(
        'Image size exceeds 10MB limit (${sizeMb}MB). Please select an image under 10MB.',
      );
    }

    final uri = Uri.parse('https://api.imgbb.com/1/upload');
    final request = http.MultipartRequest('POST', uri);
    request.fields['key'] = apiKey;

    final targetName = fileName ?? 'omnya_upload_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final isPng = targetName.toLowerCase().endsWith('.png');
    final mediaType = isPng ? MediaType('image', 'png') : MediaType('image', 'jpeg');

    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: targetName,
        contentType: mediaType,
      ),
    );

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true) {
        return ImgbbUploadResult.fromJson(json);
      }
    }

    throw Exception('ImgBB upload failed with status ${response.statusCode}: ${response.body}');
  }

  /// Upload image from local file path with strict 10MB limit check
  Future<ImgbbUploadResult> uploadFile(File file) async {
    final length = await file.length();
    if (length > maxFileSizeBytes) {
      final sizeMb = (length / (1024 * 1024)).toStringAsFixed(1);
      throw ImgbbSizeException(
        'Image size exceeds 10MB limit (${sizeMb}MB). Please select an image under 10MB.',
      );
    }

    final bytes = await file.readAsBytes();
    return uploadBytes(bytes, fileName: file.uri.pathSegments.last);
  }
}
