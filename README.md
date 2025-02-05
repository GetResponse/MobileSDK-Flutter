# GetResponseMobileSDK-Flutter

## Installation

Full developers guide available on:
https://www.getresponse.com/help/mobile-apps-technical-documentation-for-flutter.html

Add the following to your `pubspec.yaml` file:
    
```yaml
dependencies:
    getresponsemobilesdk_flutter: 
        git:
           url: https://github.com/GetResponse/MobileSDK-Flutter.git
  ```

## Usage

### Configure SDK

1. Go to app.getresponse.com > Web Push Notifications > Mobile apps to get the Application ID, Secret, and Entrypoint

2. Add initialization of GetResponseSDK and Firebase Messaging in main method:

```dart
void initGetResponse() {
  GetResponsePushNotificationService().configure(
      secret: /*secret*/,
      applicationId: /*applicationId*/,
      entrypoint: /*entrypoint*/);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  initGetResponse();
  runApp(const MyApp());
}
```

### Managing consent

1. To start sending notifications Request system permission and send consent:
    ```dart
    FirebaseMessaging.instance.requestPermission().then((notificationSettings) async {
        if (notificationSettings.authorizationStatus == AuthorizationStatus.authorized) {
            FirebaseMessaging.instance.getAPNSToken().then((apnsToken) {
                if (apnsToken != null || Platform.isAndroid) {
                    FirebaseMessaging.instance.getToken().then((fcmToken) {
                        GetResponsePushNotificationService().consent(lang: /*languageCode*/, externalId: /*externalId*/, email: /*email (optional)*/, fcmToken: fcmToken);
                    });
                }
            });
        }
    });
    ```
2. Send consent on every token refresh:
    ```dart
    FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) async {
        await GetResponsePushNotificationService().consent(lang: /*languageCode*/, externalId: /*externalId*/, email: /*email (optional)*/, fcmToken: fcmToken);
    }).onError((err) {
        /* Handle error */
    });
    ```
3. Remove consent to stop sending notifications (e.g logout):
    ```dart
    await GetResponsePushNotificationService().removeConsent()
    ```

### Handling notifications

1. Foreground notifications:
    ```dart
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        final notificationHandler = await GetResponsePushNotificationService().handleIncomingNotification(message.data, EventType.showed);
        // show notification 
    });
    ```
2. Background messages:
    - Create background handler outside of any class. Important: this handler works in background isolate so GetResponseSDK has to be
      initialize again.
    ```dart
    @pragma('vm:entry-point')
    Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
        initGetResponse();
        final notificationHandler = await GetResponsePushNotificationService().handleIncomingNotification(message.data, EventType.showed);
    }
    ```

    - Add handler to firebase configuration in main method.

     ```dart
     FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
     ```

     - Add notification service extension class in XCode for IOS:

     ```swift
     class NotificationService: UNNotificationServiceExtension {
     ...
        
         override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
             self.contentHandler = contentHandler
             bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
             if let bestAttemptContent = bestAttemptContent {
                 Messaging.serviceExtension().populateNotificationContent(bestAttemptContent, withContentHandler: contentHandler)
             }
         }
            
         ...
     }
     ```
3. Tapping background notification (not terminated):
    ```dart
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
        final notificationHandler = await GetResponsePushNotificationService().handleIncomingNotification(message.data, EventType.clicked);
    });
    ```
4. Tapping background notification (terminated):
    ```dart
    FirebaseMessaging.instance.getInitialMessage().then((message) async {
        if (message != null) {
        final notificationHandler = await GetResponsePushNotificationService().handleIncomingNotification(message.data, EventType.clicked);
    }
    });
    ```
5. Handle depending how local notifications are shown for example user flutter_local_notifications
