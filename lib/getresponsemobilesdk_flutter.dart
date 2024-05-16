library getresponsemobilesdk_flutter;

import 'dart:core';
import 'dart:io';
import 'package:getresponsemobilesdk_flutter/api_helpers.dart';
import 'package:getresponsemobilesdk_flutter/consent_model.dart';
import 'package:getresponsemobilesdk_flutter/delete_model.dart';
import 'package:getresponsemobilesdk_flutter/logger.dart';
import 'package:getresponsemobilesdk_flutter/notification_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class GetResponsePushNotificationService {
  SharedPreferences? _prefs;

  String? _secret;
  String? _applicationId;
  String? _entrypoint;
  String? _installationUUID;
  final _installationUUIDKey = "GRSDK_installationUUID";

  GetResponsePushNotificationService._privateConstructor();

  static final GetResponsePushNotificationService _instance = GetResponsePushNotificationService._privateConstructor();

  factory GetResponsePushNotificationService() {
    return _instance;
  }

  Future<void> configure({required String secret, required String applicationId, required String entrypoint}) async {
    _prefs ??= await SharedPreferences.getInstance();
    final uuid = _prefs!.getString(_installationUUIDKey);
    if (_installationUUID == null) {
      if (uuid != null) {
        _installationUUID = uuid;
      } else {
        _installationUUID = const Uuid().v4();
        _prefs!.setString(_installationUUIDKey, _installationUUID!);
      }
    }
    _secret = secret;
    _applicationId = applicationId;
    _entrypoint = entrypoint;
  }

  Future<void> consent({required String lang, required String externalId, String? email, required String fcmToken}) async {
    checkConfiguration();
    final consent =
        ConsentModel(lang: lang, externalId: externalId, email: email, fcmToken: fcmToken, platform: Platform.isIOS ? "ios" : "android");
    final token = APIHelpers().createJWTToken(secret: _secret!, applicationId: _applicationId!, installationUUID: _installationUUID!);
    return await APIHelpers().post(apiEndpoint: "${_entrypoint!}/consents", jsonData: consent.toJson(), token: token);
  }

  Future<void> removeConsent() async {
    checkConfiguration();
    final delete = DeleteModel(installationUUID: _installationUUID!);
    final token = APIHelpers().createJWTToken(secret: _secret!, applicationId: _applicationId!, installationUUID: _installationUUID!);
    return await APIHelpers().delete(apiEndpoint: "${_entrypoint!}/consents", jsonData: delete.toJson(), token: token);
  }

  void checkConfiguration() {
    assert(_secret != null && _applicationId != null && _entrypoint != null,
        "Method configure(secret: String, applicationId: String, entrypoint: String) has to be called first");
  }

  Future<NotificationHandler?> handleIncomingNotification(dynamic data, EventType eventType) async {
    if (data["issuer"] != "getresponse") {
      Logger.logMessage("Not a GetResponse notification");
      return null;
    }
    final statsUrl = data["stats_url"];
    if (statsUrl != null) {
      await APIHelpers().callUrl(apiEndpoint: eventType.getEventUrl(statsUrl));
    }
    return NotificationHandler.fromJson(data);
  }

  static Map<String, dynamic> convertStringDataToPayload(String payload) {
    final String payload0 = payload.substring(1, payload.length - 1);
    List<String> split = [];
    payload0.split(",").forEach((String s) => split.addAll(s.split(": ")));
    Map<String, dynamic> mapped = {};
    for (int i = 0; i < split.length + 1; i++) {
      if (i % 2 == 1) mapped.addAll({split[i - 1].trim().toString(): split[i].trim()});
    }
    return mapped;
  }

  Future<NotificationHandler?> handlePayload(Map<String, dynamic> payload, EventType eventType) async {
    if (payload["issuer"] != "getresponse") {
      Logger.logMessage("Not a GetResponse notification");
      return null;
    }
    final statsUrl = payload["stats_url"];
    if (statsUrl != null) {
      await APIHelpers().callUrl(apiEndpoint: eventType.getEventUrl(statsUrl));
    }
    return NotificationHandler.fromJson(payload);
  }
}
