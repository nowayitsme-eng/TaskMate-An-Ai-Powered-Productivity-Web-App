import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // AWS Bedrock Configuration
  final String _apiKey = dotenv.env['BEDROCK_API_KEY'] ?? 'YOUR_AWS_API_KEY';
  final String _region = 'us-east-1';
  final String _modelId = 'us.anthropic.claude-sonnet-4-6';

  String get _apiUrl =>
      'https://bedrock-runtime.$_region.amazonaws.com/model/${Uri.encodeComponent(_modelId)}/converse';

  // ─── AI Chat History Methods ──────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> getChatHistory(String providedUserId) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? providedUserId;
    return _db
        .collection('users')
        .doc(userId)
        .collection('chat')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  Future<void> saveMessage(String providedUserId, String role, String content) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? providedUserId;
    return _db.collection('users').doc(userId).collection('chat').add({
      'role': role,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> clearChat(String providedUserId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? providedUserId;
    final batch = _db.batch();
    final snapshot =
        await _db.collection('users').doc(userId).collection('chat').get();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ─── Helpers for Converse API Format ─────────────────────────────────────

  // Converts standard [{role: 'user', content: '...'}] to Converse API format
  List<Map<String, dynamic>> _formatMessages(
      List<Map<String, String>> history) {
    final conversationMessages =
        history.where((msg) => msg['role'] != 'system').toList();
    return conversationMessages.map((msg) {
      return {
        'role': msg['role'],
        'content': [
          {'text': msg['content']}
        ]
      };
    }).toList();
  }

  // Extracts system messages
  List<Map<String, dynamic>> _extractSystemPrompts(
      List<Map<String, String>> history) {
    final systemMessages =
        history.where((msg) => msg['role'] == 'system').toList();
    return systemMessages.map((msg) => {'text': msg['content']}).toList();
  }

  /// Low-level call to the Bedrock Converse API with a single user message + system prompt.
  Future<String> _callBedrock({
    required String systemPrompt,
    required String userMessage,
  }) async {
    await _checkRateLimit();
    final payload = {
      'system': [
        {'text': systemPrompt}
      ],
      'messages': [
        {
          'role': 'user',
          'content': [
            {'text': userMessage}
          ]
        }
      ],
    };

    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['output']['message']['content'][0]['text'] ?? '';
    } else {
      throw Exception('API error: ${response.statusCode} - ${response.body}');
    }
  }

  // ─── AI API Requests ──────────────────────────────────────────────────────

  Future<String> getAiResponse(List<Map<String, String>> history) async {
    try {
      await _checkRateLimit();
      final messages = _formatMessages(history);
      final systemPrompts = _extractSystemPrompts(history);

      final payload = {
        'messages': messages,
      };

      if (systemPrompts.isNotEmpty) {
        payload['system'] = systemPrompts;
      }

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['output']['message']['content'][0]['text'] ?? '';
      } else {
        throw Exception('API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to get AI response: $e');
    }
  }

  /// Helper to strictly extract a JSON array from AI output
  String _extractJsonArray(String raw) {
    final start = raw.indexOf('[');
    final end = raw.lastIndexOf(']');
    if (start == -1 || end == -1 || start > end) {
      throw Exception('Failed to find JSON array in AI response');
    }
    return raw.substring(start, end + 1);
  }

  Future<String> summarizeText(String text) async {
    try {
      final result = await _callBedrock(
        systemPrompt:
            'Provide a concise bullet point summary in markdown format. Focus on key concepts and main ideas. Use **bold** for important terms.',
        userMessage: text,
      );
      return result;
    } catch (e) {
      return localSummarizerFallback(text);
    }
  }

  String localSummarizerFallback(String text) {
    final cleanText = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    final sentences = cleanText.split(RegExp(r'(?<=[.!?])\s+'));
    final validSentences =
        sentences.where((s) => s.length > 20 && s.length < 200).toList();

    if (validSentences.isEmpty) {
      return "• Couldn't generate summary from this text";
    }

    final bullets = validSentences.take(3).map((s) => '• $s').join('\n\n');
    return '$bullets\n\n*Note: This is a local fallback summary as the AI service was unreachable.*';
  }

  // ─── Feature 1: Task Decomposition ───────────────────────────────────────

  /// Breaks a large task title into 5-7 actionable sub-tasks.
  /// Returns a list of sub-task title strings.
  Future<List<String>> decomposeTask(String taskTitle) async {
    const systemPrompt = '''
You are a productivity expert. Given a task title, break it down into 5 to 7 specific, actionable sub-tasks.
Respond ONLY with a valid JSON array of strings. No explanation, no markdown, no code block. Example:
["Research the topic","Create an outline","Write the introduction","Write the body paragraphs","Review and edit","Submit"]
''';

    try {
      final raw = await _callBedrock(
        systemPrompt: systemPrompt,
        userMessage: 'Break down this task: "$taskTitle"',
      );

      final cleaned = _extractJsonArray(raw);

      final List<dynamic> parsed = jsonDecode(cleaned);
      return parsed.map((e) => e.toString()).toList();
    } catch (e) {
      print('DecomposeTask Error: $e');
      // Fallback: generic sub-tasks
      return [
        'Research "$taskTitle"',
        'Plan approach for "$taskTitle"',
        'Draft first version',
        'Review and refine',
        'Finalize and submit',
      ];
    }
  }

  // ─── Feature 2a: Flashcard Generation ────────────────────────────────────

  /// Generates a list of flashcard Q-and-A pairs from study notes.
  /// Returns a List of Maps with keys 'question' and 'answer'.
  Future<List<Map<String, String>>> generateFlashcards(String text) async {
    const systemPrompt = '''
You are a study assistant. Generate exactly 5 flashcards from the provided text.
Respond ONLY with a valid JSON array of objects, where each object has a "question" and an "answer".
Example:
[{"question": "What is Mitochondria?", "answer": "The powerhouse of the cell."}]
No other text, markdown, or explanation.
''';

    try {
      final raw = await _callBedrock(
        systemPrompt: systemPrompt,
        userMessage: 'Generate flashcards from: "$text"',
      );

      final cleaned = _extractJsonArray(raw);

      final List<dynamic> parsed = jsonDecode(cleaned);
      return parsed.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return {
          'question': m['question']?.toString() ?? 'Error parsing question',
          'answer': m['answer']?.toString() ?? 'Error parsing answer',
        };
      }).toList();
    } catch (e) {
      print('GenerateFlashcards Error: $e');
      return [
        {'question': 'Failed to generate flashcards', 'answer': e.toString()}
      ];
    }
  }

  // ─── Rate Limiter ─────────────────────────────────────────────────────────

  Future<void> _checkRateLimit() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception("Unauthorized: Please log in.");
    
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final ref = _db.collection('users').doc(userId).collection('limits').doc('ai_$today');
    
    final doc = await ref.get();
    if (doc.exists) {
      final count = doc.data()?['count'] ?? 0;
      if (count >= 20) {
        throw Exception("Rate limit exceeded. Maximum 20 AI requests per day.");
      }
      await ref.update({'count': FieldValue.increment(1)});
    } else {
      await ref.set({'count': 1, 'date': today});
    }
  }

  // ─── Feature 2b: Quiz Generation ─────────────────────────────────────────

  /// Generates a multiple-choice quiz from study notes.
  /// Returns a List of Maps with keys 'question', 'options' (List of String), 'correctIndex' (int).
  Future<List<Map<String, dynamic>>> generateQuiz(String notes) async {
    const systemPrompt = '''
You are a quiz creator. Given study notes, generate 5 multiple-choice questions.
Respond ONLY with a valid JSON array. Each item must have:
- "question": string
- "options": array of exactly 4 strings (A, B, C, D choices)
- "correctIndex": integer (0-based index of the correct option)
No explanation, no markdown code block. Example:
[{"question":"What is H2O?","options":["Carbon dioxide","Water","Oxygen","Hydrogen"],"correctIndex":1}]
''';

    try {
      final raw = await _callBedrock(
        systemPrompt: systemPrompt,
        userMessage: 'Create a quiz from these notes:\n\n$notes',
      );

      final cleaned = _extractJsonArray(raw);

      final List<dynamic> parsed = jsonDecode(cleaned);
      return parsed
          .map<Map<String, dynamic>>((e) => {
                'question': e['question']?.toString() ?? '',
                'options': List<String>.from(e['options'] ?? []),
                'correctIndex': (e['correctIndex'] as num?)?.toInt() ?? 0,
              })
          .toList();
    } catch (e) {
      print('GenerateQuiz Error: $e');
      return [
        {
          'question': 'Could not generate quiz',
          'options': [
            'Please try again',
            'Use more detailed notes',
            'At least 100 words',
            'Then retry'
          ],
          'correctIndex': 1,
        },
      ];
    }
  }

  // ─── Feature 3: Weekly AI Insights ───────────────────────────────────────

  /// Returns the cached weekly insight for this user if it is less than 7 days old.
  /// Returns null if no cache or if stale.
  Future<String?> getLastWeeklyInsight(String userId) async {
    try {
      final doc = await _db
          .collection('users')
          .doc(userId)
          .collection('insights')
          .doc('weekly')
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      final generatedAt = (data['generatedAt'] as Timestamp?)?.toDate();
      if (generatedAt == null) return null;

      final age = DateTime.now().difference(generatedAt);
      if (age.inDays >= 7) return null; // Stale — needs refresh

      return data['insight'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Generates a personalized weekly insight and caches it in Firestore.
  Future<String> generateWeeklyInsight({
    required String userId,
    required int completedTasks,
    required int overdueTasks,
    required int pomodoroMinutes,
    required List<String> topCategories,
  }) async {
    const systemPrompt = '''
You are an encouraging personal productivity coach named Aria. 
Given a user's weekly stats, write a SHORT (3-5 sentence), warm, personalized motivational insight.
- Be specific about the numbers provided.
- Give one concrete tip for improvement.
- Use an upbeat tone. No bullet points — write in flowing prose.
- Do NOT use markdown formatting. Plain text only.
''';

    final categorySummary = topCategories.isEmpty
        ? 'no specific categories'
        : topCategories.join(', ');

    final userMessage = '''
My stats for this past week:
- Completed tasks: $completedTasks
- Overdue tasks: $overdueTasks
- Total Pomodoro focus time: $pomodoroMinutes minutes
- Top categories worked on: $categorySummary

Please give me my weekly insight.
''';

    try {
      final insight = await _callBedrock(
        systemPrompt: systemPrompt,
        userMessage: userMessage,
      );

      // Cache the result in Firestore
      await _db
          .collection('users')
          .doc(userId)
          .collection('insights')
          .doc('weekly')
          .set({
        'insight': insight,
        'generatedAt': FieldValue.serverTimestamp(),
        'stats': {
          'completedTasks': completedTasks,
          'overdueTasks': overdueTasks,
          'pomodoroMinutes': pomodoroMinutes,
          'topCategories': topCategories,
        },
      });

      return insight;
    } catch (e) {
      return "Great effort this week! You completed $completedTasks tasks and put in $pomodoroMinutes minutes of focused work. Keep building on your momentum — every session counts! Try to tackle those overdue items first thing next week to start fresh.";
    }
  }
}
