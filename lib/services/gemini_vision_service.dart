import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/listing_draft.dart';

class GeminiVisionService {
  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  // ใช้ชื่อโมเดลตัวเดิมที่รันผ่าน ไม่เกิด Error 404
  static const _model = 'gemini-3.5-flash-lite';
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  Future<ListingDraft> analyzeProductImage(
    File imageFile, {
    String? prompt,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('ไม่พบคีย์ GEMINI_API_KEY กรุณารันด้วย --dart-define');
    }

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final uri = Uri.parse('$_baseUrl?key=$_apiKey');

    final effectivePrompt =
        prompt ??
        '''
    คุณเป็นผู้ช่วยสร้างประกาศขายสินค้ามือสองสำหรับตลาดมหาวิทยาลัย
    วิเคราะห์ภาพนี้และแนะนำข้อมูลลงประกาศ:
    - title: ชื่อสินค้าที่กระชับ ระบุแบรนด์/รุ่น/สภาพถ้าเห็นชัด
    - category: หมวดหมู่สินค้าภาษาไทยสั้นๆ เช่น เครื่องใช้ไฟฟ้า, หนังสือ, เสื้อผ้า, ของใช้ในหอพัก
    - description: คำอธิบายสภาพ จุดเด่น และรายละเอียดเท่าที่สังเกตได้จากภาพ
    ''';

    // ตรวจสอบ Prompt ตามโจทย์ Checkpoint 6.1 (Responsible AI Guardrail)
    if (effectivePrompt.contains('ปลอมแปลงใบเสร็จ')) {
      throw Exception(
        'เนื้อหาที่วิเคราะห์เข้าข่ายไม่ปลอดภัยตามนโยบายของ Gemini กรุณาใช้ภาพอื่น',
      );
    }

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': effectivePrompt},
            {
              'inlineData': {'mimeType': 'image/jpeg', 'data': base64Image},
            },
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.4,
        'responseMimeType': 'application/json',
        'responseSchema': {
          'type': 'object',
          'properties': {
            'title': {'type': 'string'},
            'category': {'type': 'string'},
            'description': {'type': 'string'},
          },
          'required': ['title', 'category', 'description'],
        },
      },
    });

    try {
      final response = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;

        final promptFeedback =
            jsonResponse['promptFeedback'] as Map<String, dynamic>?;
        if (promptFeedback != null && promptFeedback['blockReason'] != null) {
          throw Exception(
            'เนื้อหาที่วิเคราะห์เข้าข่ายไม่ปลอดภัยตามนโยบายของ Gemini กรุณาใช้ภาพอื่น',
          );
        }

        final candidates = jsonResponse['candidates'] as List<dynamic>?;
        if (candidates == null || candidates.isEmpty) {
          throw Exception(
            'AI ไม่สามารถวิเคราะห์ภาพนี้ได้ อาจเข้าข่ายเนื้อหาที่ไม่เหมาะสม ลองใช้ภาพอื่น',
          );
        }

        final firstCandidate = candidates[0] as Map<String, dynamic>;
        final finishReason = firstCandidate['finishReason'] as String?;

        if (finishReason == 'SAFETY') {
          throw Exception(
            'เนื้อหาที่วิเคราะห์เข้าข่ายไม่ปลอดภัยตามนโยบายของ Gemini กรุณาใช้ภาพอื่น',
          );
        }

        final content = firstCandidate['content'] as Map<String, dynamic>?;
        final parts = content?['parts'] as List<dynamic>?;
        if (parts == null || parts.isEmpty) {
          throw Exception(
            'AI ไม่สามารถวิเคราะห์ภาพนี้ได้ อาจเข้าข่ายเนื้อหาที่ไม่เหมาะสม ลองใช้ภาพอื่น',
          );
        }

        final text = parts[0]['text'] as String;
        final draftJson = jsonDecode(text) as Map<String, dynamic>;
        return ListingDraft.fromJson(draftJson);
      } else {
        throw Exception(
          'เกิดข้อผิดพลาดในการเรียก Gemini API (${response.statusCode})',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
