import 'package:neurocompanion_flutter/services/api_client.dart';
import 'package:neurocompanion_flutter/services/api_exceptions.dart';

/// Caregiver API Service
/// Handles all caregiver-related operations matching web app functionality
class CaregiverService {
  final ApiClient _api;

  CaregiverService({required ApiClient apiClient}) : _api = apiClient;

  /// Register a new caregiver
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? specialization,
  }) async {
    final json = await _api.post(
      '/caregiver/register',
      authenticated: false,
      body: {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        if (phone != null) 'phone': phone,
        if (specialization != null) 'specialization': specialization,
      },
    );

    if (json is! Map) {
      throw const ApiException(message: 'Unexpected registration response');
    }

    return json is Map<String, dynamic> ? json : json.cast<String, dynamic>();
  }

  /// Verify OTP for registration
  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final json = await _api.post(
      '/caregiver/verify-otp',
      authenticated: false,
      body: {
        'email': email.trim(),
        'otp': otp.trim(),
      },
    );

    if (json is! Map) {
      throw const ApiException(message: 'Unexpected OTP verification response');
    }

    return json is Map<String, dynamic> ? json : json.cast<String, dynamic>();
  }

  /// Verify 2FA for login
  Future<Map<String, dynamic>> verify2FA({
    required String caregiverId,
    required String otp,
  }) async {
    final json = await _api.post(
      '/caregiver/verify-2fa',
      authenticated: false,
      body: {
        'caregiverId': caregiverId,
        'otp': otp.trim(),
      },
    );

    if (json is! Map) {
      throw const ApiException(message: 'Unexpected 2FA verification response');
    }

    return json is Map<String, dynamic> ? json : json.cast<String, dynamic>();
  }

  /// Login caregiver
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final json = await _api.post(
      '/caregiver/login',
      authenticated: false,
      body: {
        'email': email.trim(),
        'password': password,
      },
    );

    if (json is! Map) {
      throw const ApiException(message: 'Unexpected login response');
    }

    return json is Map<String, dynamic> ? json : json.cast<String, dynamic>();
  }

  /// Get caregiver profile
  Future<Map<String, dynamic>> getProfile() async {
    final json = await _api.get('/caregiver/me', authenticated: true);

    if (json is! Map) {
      throw const ApiException(message: 'Unexpected profile response');
    }

    return json is Map<String, dynamic> ? json : json.cast<String, dynamic>();
  }

  /// Update caregiver profile
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final json = await _api.put('/caregiver/me', authenticated: true, body: data);

    if (json is! Map) {
      throw const ApiException(message: 'Unexpected update response');
    }

    return json is Map<String, dynamic> ? json : json.cast<String, dynamic>();
  }

  /// Toggle 2FA
  Future<Map<String, dynamic>> toggle2FA() async {
    final json = await _api.post('/caregiver/toggle-2fa', authenticated: true);

    if (json is! Map) {
      throw const ApiException(message: 'Unexpected 2FA response');
    }

    return json is Map<String, dynamic> ? json : json.cast<String, dynamic>();
  }

  /// Change caregiver password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _api.put(
      '/caregiver/me/password',
      authenticated: true,
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  /// Get list of all patients
  Future<List<Map<String, dynamic>>> getPatients() async {
    final json = await _api.get('/caregiver/patients', authenticated: true);

    if (json is! Map) {
      throw const ApiException(message: 'Unexpected patients response');
    }

    final patients = json['patients'];
    if (patients is! List) return [];

    return patients.map((p) {
      if (p is Map<String, dynamic>) return p;
      if (p is Map) return p.cast<String, dynamic>();
      return <String, dynamic>{};
    }).toList();
  }

  /// Get detailed patient information
  Future<Map<String, dynamic>> getPatientDetail(String patientId) async {
    final json = await _api.get('/caregiver/patient/$patientId', authenticated: true);

    if (json is! Map) {
      throw const ApiException(message: 'Unexpected patient detail response');
    }

    return json is Map<String, dynamic> ? json : json.cast<String, dynamic>();
  }

  /// Add patient to caregiver
  Future<void> addPatient(String patientId) async {
    await _api.post(
      '/caregiver/add-patient',
      authenticated: true,
      body: {'patientId': patientId},
    );
  }

  /// Remove patient from caregiver
  Future<void> removePatient(String patientId) async {
    await _api.delete('/caregiver/patient/$patientId', authenticated: true);
  }

  /// Send message to patient
  Future<void> sendMessage({
    required String recipientId,
    required String message,
    String? subject,
    String? priority,
  }) async {
    await _api.post(
      '/caregiver/message/send',
      authenticated: true,
      body: {
        'recipientId': recipientId,
        'message': message,
        if (subject != null) 'subject': subject,
        if (priority != null) 'priority': priority,
      },
    );
  }

  /// Get message thread with patient
  Future<List<Map<String, dynamic>>> getMessages(String patientId) async {
    final json = await _api.get('/caregiver/messages/$patientId', authenticated: true);

    if (json is! Map) {
      throw const ApiException(message: 'Unexpected messages response');
    }

    final messages = json['messages'];
    if (messages is! List) return [];

    return messages.map((m) {
      if (m is Map<String, dynamic>) return m;
      if (m is Map) return m.cast<String, dynamic>();
      return <String, dynamic>{};
    }).toList();
  }

  /// Create appointment
  Future<Map<String, dynamic>> createAppointment({
    required String patientId,
    required DateTime scheduledDate,
    int? duration,
    String? type,
    String? title,
    String? notes,
    String? meetingLink,
  }) async {
    final json = await _api.post(
      '/caregiver/appointment/create',
      authenticated: true,
      body: {
        'patientId': patientId,
        'scheduledDate': scheduledDate.toIso8601String(),
        if (duration != null) 'duration': duration,
        if (type != null) 'type': type,
        if (title != null) 'title': title,
        if (notes != null) 'notes': notes,
        if (meetingLink != null) 'meetingLink': meetingLink,
      },
    );

    if (json is! Map) {
      throw const ApiException(message: 'Unexpected appointment response');
    }

    return json is Map<String, dynamic> ? json : json.cast<String, dynamic>();
  }

  /// Get caregiver appointments
  Future<List<Map<String, dynamic>>> getAppointments() async {
    final json = await _api.get('/caregiver/appointments', authenticated: true);

    if (json is! Map) {
      throw const ApiException(message: 'Unexpected appointments response');
    }

    final appointments = json['appointments'];
    if (appointments is! List) return [];

    return appointments.map((a) {
      if (a is Map<String, dynamic>) return a;
      if (a is Map) return a.cast<String, dynamic>();
      return <String, dynamic>{};
    }).toList();
  }

  /// Get all invites
  Future<List<Map<String, dynamic>>> getInvites() async {
    final json = await _api.get('/invites', authenticated: true);

    if (json is! Map) {
      throw const ApiException(message: 'Unexpected invites response');
    }

    final invites = json['invites'];
    if (invites is! List) return [];

    return invites.map((i) {
      if (i is Map<String, dynamic>) return i;
      if (i is Map) return i.cast<String, dynamic>();
      return <String, dynamic>{};
    }).toList();
  }

  /// Create patient invite
  Future<Map<String, dynamic>> createInvite({
    required String patientName,
    required String patientEmail,
    int? age,
    String? neurotype,
  }) async {
    final json = await _api.post(
      '/invites',
      authenticated: true,
      body: {
        'patientName': patientName,
        'patientEmail': patientEmail,
        if (age != null) 'age': age,
        if (neurotype != null) 'neurotype': neurotype,
      },
    );

    if (json is! Map) {
      throw const ApiException(message: 'Unexpected invite creation response');
    }

    return json is Map<String, dynamic> ? json : json.cast<String, dynamic>();
  }

  /// Get invite code by invite ID
  Future<Map<String, dynamic>> getInviteCode(String inviteId) async {
    final json = await _api.get('/invites/$inviteId/code', authenticated: true);

    if (json is! Map) {
      throw const ApiException(message: 'Unexpected invite code response');
    }

    return json is Map<String, dynamic> ? json : json.cast<String, dynamic>();
  }

  /// Regenerate invite code
  Future<Map<String, dynamic>> regenerateInvite(String inviteId) async {
    final json = await _api.post('/invites/$inviteId/regenerate', authenticated: true);

    if (json is! Map) {
      throw const ApiException(message: 'Unexpected regenerate response');
    }

    return json is Map<String, dynamic> ? json : json.cast<String, dynamic>();
  }

  /// Revoke invite
  Future<Map<String, dynamic>> revokeInvite(String inviteId) async {
    final json = await _api.post('/invites/$inviteId/revoke', authenticated: true);

    if (json is! Map) {
      throw const ApiException(message: 'Unexpected revoke response');
    }

    return json is Map<String, dynamic> ? json : json.cast<String, dynamic>();
  }
}
