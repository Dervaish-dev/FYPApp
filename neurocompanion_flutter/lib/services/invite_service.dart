import 'package:neurocompanion_flutter/services/api_client.dart';

class InviteLookupResult {
  final String maskedEmail;

  const InviteLookupResult({required this.maskedEmail});
}

class InviteSendOtpResult {
  final String maskedEmail;

  const InviteSendOtpResult({required this.maskedEmail});
}

class InviteVerifyOtpResult {
  final String claimToken;

  const InviteVerifyOtpResult({required this.claimToken});
}

class InviteService {
  final ApiClient _api;

  InviteService({required ApiClient apiClient}) : _api = apiClient;

  Future<InviteLookupResult> lookupCode(String code) async {
    final json = await _api.post(
      '/invites/claim/lookup',
      authenticated: false,
      body: {'code': code.trim()},
    );

    final maskedEmail = (json is Map && json['maskedEmail'] != null)
        ? json['maskedEmail'].toString()
        : '';

    return InviteLookupResult(maskedEmail: maskedEmail);
  }

  Future<InviteSendOtpResult> sendOtp({required String code, required String email}) async {
    final json = await _api.post(
      '/invites/claim/send-otp',
      authenticated: false,
      body: {
        'code': code.trim(),
        'email': email.trim(),
      },
    );

    final maskedEmail = (json is Map && json['maskedEmail'] != null)
        ? json['maskedEmail'].toString()
        : '';

    return InviteSendOtpResult(maskedEmail: maskedEmail);
  }

  Future<InviteVerifyOtpResult> verifyOtp({
    required String code,
    required String email,
    required String otp,
  }) async {
    final json = await _api.post(
      '/invites/claim/verify-otp',
      authenticated: false,
      body: {
        'code': code.trim(),
        'email': email.trim(),
        'otp': otp.trim(),
      },
    );

    final claimToken = (json is Map && json['claimToken'] != null)
        ? json['claimToken'].toString()
        : '';

    return InviteVerifyOtpResult(claimToken: claimToken);
  }
}
