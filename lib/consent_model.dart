class ConsentModel {
  final String lang;
  final String externalId;
  final String? email;
  final String fcmToken;
  final String platform;

  ConsentModel({required this.lang, required this.externalId, this.email, required this.fcmToken, required this.platform});

  Map<String, String?> toJson() {
    return {
      'lang': lang,
      'external_id': externalId,
      'email': email,
      'fcm_token': fcmToken,
      'platform': platform
    };
  }
}