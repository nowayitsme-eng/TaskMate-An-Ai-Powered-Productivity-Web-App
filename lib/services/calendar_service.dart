import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import '../models/task.dart';

/// Two-way Google Calendar Sync Service.
///
/// TaskMate → Google Calendar (write):
///   createCalendarEvent, updateCalendarEvent, deleteCalendarEvent
///
/// Google Calendar → TaskMate (read):
///   syncFromCalendar — fetches upcoming calendar events and creates
///   corresponding tasks in Firestore that don't already exist.
class CalendarService {
  static final CalendarService _instance = CalendarService._internal();
  factory CalendarService() => _instance;
  CalendarService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [gcal.CalendarApi.calendarScope],
  );

  gcal.CalendarApi? _calendarApi;
  bool _isConnected = false;

  // Fix 9: Debounce calendar updates to prevent API rate-limiting
  // Maps task ID → pending debounce timer
  final Map<String, Timer> _debounceTimers = {};

  bool get isConnected => _isConnected;

  // ─── Auth ─────────────────────────────────────────────────────────────────

  /// Signs into Google and initializes the Calendar API.
  /// Returns true on success.
  Future<bool> connect() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return false;

      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient == null) return false;

      _calendarApi = gcal.CalendarApi(httpClient);
      _isConnected = true;

      // Persist connection state for the current user
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await _db.collection('users').doc(userId).set({
          'calendarConnected': true,
          'calendarEmail': account.email,
        }, SetOptions(merge: true));
      }

      return true;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  /// Disconnects from Google Calendar and clears the API instance.
  Future<void> disconnect() async {
    await _googleSignIn.signOut();
    _calendarApi = null;
    _isConnected = false;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await _db.collection('users').doc(userId).set({
        'calendarConnected': false,
        'calendarEmail': null,
      }, SetOptions(merge: true));
    }
  }

  /// Silently restores a previously connected session.
  Future<void> tryRestoreSession() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account == null) return;

      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient == null) return;

      _calendarApi = gcal.CalendarApi(httpClient);
      _isConnected = true;
    } catch (_) {
      _isConnected = false;
    }
  }

  // ─── TaskMate → Google Calendar (Write) ───────────────────────────────────

  /// Creates a Google Calendar event for the given task.
  /// Returns the event ID to be stored back on the TaskModel.
  Future<String?> createCalendarEvent(TaskModel task) async {
    if (_calendarApi == null) return null;
    try {
      final event = _taskToEvent(task);
      final created = await _calendarApi!.events.insert(event, 'primary');
      return created.id;
    } catch (e) {
      return null;
    }
  }

  /// Updates the existing Google Calendar event linked to the task.
  /// Debounced: rapid consecutive calls for the same task collapse into one.
  void updateCalendarEvent(TaskModel task) {
    if (_calendarApi == null || task.calendarEventId == null) return;
    // Cancel any pending update for this task
    _debounceTimers[task.id]?.cancel();
    _debounceTimers[task.id] = Timer(const Duration(seconds: 2), () async {
      _debounceTimers.remove(task.id);
      try {
        final event = _taskToEvent(task);
        await _calendarApi!.events.update(
          event,
          'primary',
          task.calendarEventId!,
        );
      } catch (_) {}
    });
  }

  /// Deletes the Google Calendar event linked to the task.
  Future<void> deleteCalendarEvent(String calendarEventId) async {
    if (_calendarApi == null) return;
    try {
      await _calendarApi!.events.delete('primary', calendarEventId);
    } catch (_) {}
  }

  // ─── Google Calendar → TaskMate (Read) ────────────────────────────────────

  /// Fetches Google Calendar events for the next 30 days and creates
  /// TaskModel entries in Firestore for any event not already linked.
  /// Returns the number of new tasks created.
  Future<int> syncFromCalendar(String userId) async {
    if (_calendarApi == null) return 0;

    final now = DateTime.now().toUtc();
    final thirtyDaysOut = now.add(const Duration(days: 30));

    try {
      final events = await _calendarApi!.events.list(
        'primary',
        timeMin: now,
        timeMax: thirtyDaysOut,
        singleEvents: true,
        orderBy: 'startTime',
      );

      if (events.items == null || events.items!.isEmpty) return 0;

      // Get all existing calendarEventIds from Firestore to avoid duplicates
      final existingSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .where('calendarEventId', isNull: false)
          .get();

      final existingIds = existingSnapshot.docs
          .map((d) => d.data()['calendarEventId'] as String?)
          .toSet();

      int created = 0;
      for (final event in events.items!) {
        if (event.id == null) continue;
        if (existingIds.contains(event.id)) continue; // Already synced

        final startTime = event.start?.dateTime ?? event.start?.date;
        if (startTime == null) continue;

        // Build a TaskModel from the calendar event
        final task = TaskModel(
          id: '',
          text: event.summary ?? 'Calendar Event',
          dueDate: startTime,
          calendarEventId: event.id,
        );

        final batch = _db.collection('users').doc(userId).collection('tasks');
        await batch.add({
          ...task.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
          'source': 'google_calendar',
        });

        created++;
      }
      return created;
    } catch (e) {
      return 0;
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  gcal.Event _taskToEvent(TaskModel task) {
    final summary = task.completed ? '✅ ${task.text}' : task.text;
    final description =
        'Synced from TaskMate${task.subject != null ? ' • ${task.subject}' : ''}';

    return gcal.Event()
      ..summary = summary
      ..description = description
      ..start = (gcal.EventDateTime()
        ..dateTime = task.dueDate.toUtc()
        ..timeZone = 'UTC')
      ..end = (gcal.EventDateTime()
        ..dateTime = task.dueDate.add(const Duration(hours: 1)).toUtc()
        ..timeZone = 'UTC')
      ..source = (gcal.EventSource()
        ..title = 'TaskMate'
        ..url = 'https://taskmate.app');
  }
}
