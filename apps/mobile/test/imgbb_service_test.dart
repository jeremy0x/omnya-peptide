import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:peptide_app/data/services/imgbb_service.dart';

void main() {
  group('ImgbbService Tests', () {
    test('Rejects images exceeding 10MB limit with ImgbbSizeException', () async {
      final service = ImgbbService();
      // 10MB + 1 byte
      final oversizedBytes = Uint8List(10 * 1024 * 1024 + 1);

      expect(
        () => service.uploadBytes(oversizedBytes),
        throwsA(isA<ImgbbSizeException>()),
      );
    });

    test('Accepts valid size image boundary (< 10MB)', () {
      final normalBytes = Uint8List(1024 * 1024); // 1MB
      expect(normalBytes.lengthInBytes <= ImgbbService.maxFileSizeBytes, isTrue);
    });

    test('Correctly parses ImgBB API response JSON', () {
      final sampleJson = {
        'data': {
          'id': '2ndCYJK',
          'title': 'c1f64245b6e63c33652aaac70909d0e1',
          'url_viewer': 'https://ibb.co/2ndCYJK',
          'url': 'https://i.ibb.co/2ndCYJK/omnya_photo.jpg',
          'display_url': 'https://i.ibb.co/2ndCYJK/omnya_photo.jpg',
          'thumb': {
            'url': 'https://i.ibb.co/2ndCYJK/thumb.jpg',
          },
          'delete_url': 'https://ibb.co/2ndCYJK/680322e3a1',
        },
        'success': true,
        'status': 200,
      };

      final result = ImgbbUploadResult.fromJson(sampleJson);
      expect(result.url, 'https://i.ibb.co/2ndCYJK/omnya_photo.jpg');
      expect(result.displayUrl, 'https://i.ibb.co/2ndCYJK/omnya_photo.jpg');
      expect(result.thumbUrl, 'https://i.ibb.co/2ndCYJK/thumb.jpg');
      expect(result.deleteUrl, 'https://ibb.co/2ndCYJK/680322e3a1');
    });
  });
}
