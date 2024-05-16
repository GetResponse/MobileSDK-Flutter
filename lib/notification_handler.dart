class NotificationHandler {
  final String? title;
  final String? body;
  final String? imageUrl;
  final ActionType action;
  final String? redirectionDestination;
  final String channelId;
  final Map<String, String> customData;

  final _keysToFilterCustomData = [
    "aps",
    "issuer",
    "redirect_type",
    "redirect_destination",
    "stats_url",
    "google.c.fid",
    "fcm_options",
    "gcm.message_id",
    "google.c.a.e",
    "google.c.sender.id"
  ];

  NotificationHandler.fromJson(dynamic data)
      : title = data["title"],
        body = data["body"],
        imageUrl = data["image"],
        action = data["redirectType"] == "deep_link"
            ? ActionType.deeplink
            : data["redirectType"] == "open_app"
                ? ActionType.openApp
                : ActionType.openURL,
        redirectionDestination = data["redirect_destination"],
        channelId = data["channel_id"] ?? "default",
        customData = data["customData"] != null ? data["customData"] as Map<String, String> : {} {
    customData.removeWhere((key, value) => _keysToFilterCustomData.contains(key));
  }

  NotificationHandler.fromPayload(Map<String, dynamic> payload)
      : title = payload["title"],
        body = payload["body"],
        imageUrl = payload["image"],
        action = payload["redirectType"] == "deep_link"
            ? ActionType.deeplink
            : payload["redirectType"] == "open_app"
                ? ActionType.openApp
                : ActionType.openURL,
        redirectionDestination = payload["redirect_destination"],
        channelId = payload["channel_id"] ?? "default",
      customData = payload["customData"] != null ? (payload["customData"] as Map<String, String>) : {} {
    customData.removeWhere((key, value) => _keysToFilterCustomData.contains(key));
  }

  @override
  String toString() {
    return 'NotificationHandler{title: $title, body: $body, imageUrl: $imageUrl, action: $action, redirectionDestination: $redirectionDestination, channelId: $channelId, customData: $customData}';
  }
}

enum EventType {
  closed("cl"),
  showed("sh"),
  clicked("cl");

  final String value;

  const EventType(this.value);

  String getEventUrl(String url) {
    return "${url}act=$value";
  }
}

enum ActionType { openApp, openURL, deeplink }
