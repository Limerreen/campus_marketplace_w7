import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const _model = 'gemini-3.5-flash-lite';
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  Future<String> generateText(String prompt) async {
    final uri = Uri.parse('$_baseUrl?key=$_apiKey');

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {'temperature': 0.4, 'maxOutputTokens': 8192},
    });

    return _sendRequest(uri, body);
  }

  Future<String> generateTextFromImage(
    String prompt,
    String base64Image,
  ) async {
    final uri = Uri.parse('$_baseUrl?key=$_apiKey');

    final strictPrompt =
        '$prompt\n(คำเตือนสำคัญ: จงตอบเป็น JSON ที่สั้นและกระชับที่สุด ห้ามเกิน 300 ตัวอักษร)';

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': strictPrompt},
            {
              'inlineData': {'mimeType': 'image/jpeg', 'data': base64Image},
            },
          ],
        },
      ],
      'generationConfig': {'temperature': 0.4, 'maxOutputTokens': 8192},
    });

    return _sendRequest(uri, body);
  }

  Future<String> _sendRequest(Uri uri, String body) async {
    try {
      final response = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;

        final candidates = json['candidates'] as List<dynamic>?;
        if (candidates == null || candidates.isEmpty) {
          throw Exception('Gemini ไม่ส่งคำตอบกลับมา (candidates ว่างเปล่า)');
        }

        final content = candidates[0]['content'] as Map<String, dynamic>?;
        final parts = content?['parts'] as List<dynamic>?;
        if (parts == null || parts.isEmpty) {
          throw Exception('Gemini ส่งคำตอบกลับมาในรูปแบบที่ไม่ถูกต้อง');
        }

        return parts[0]['text'] as String;
      }

      if (response.statusCode == 400) {
        throw Exception(
          'API Key ไม่ถูกต้อง หรือ Request มีรูปแบบผิดพลาด (400)',
        );
      } else if (response.statusCode == 403) {
        throw Exception('ไม่มีสิทธิ์เข้าถึง API กรุณาตรวจสอบ API Key (403)');
      } else if (response.statusCode == 404) {
        throw Exception('ไม่พบโมเดล กรุณาตรวจสอบชื่อโมเดลและ URL (404)');
      } else if (response.statusCode == 429) {
        throw Exception(
          'เรียกใช้ API เกินโควตาที่กำหนด กรุณารอสักครู่แล้วลองใหม่ (429)',
        );
      } else if (response.statusCode == 503) {
        throw Exception('เซิร์ฟเวอร์ Gemini ไม่พร้อมให้บริการชั่วคราว (503)');
      }

      throw Exception(
        'เกิดข้อผิดพลาดในการเรียก Gemini API (สถานะ ${response.statusCode})',
      );
    } on http.ClientException {
      throw Exception(
        'ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้ กรุณาตรวจสอบการเชื่อมต่อ',
      );
    } catch (e) {
      rethrow;
    }
  }
}
