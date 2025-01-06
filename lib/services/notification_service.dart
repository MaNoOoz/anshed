//
// class NotificationService {
//   FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
//
//   Future<void> initialize() async {
//     final InitializationSettings initializationSettings = InitializationSettings(
//       android: AndroidInitializationSettings('@mipmap/ic_launcher'),
//     );
//
//     await flutterLocalNotificationsPlugin.initialize(initializationSettings);
//   }
//
//   Future<void> showNotification(String title, String body) async {
//     const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
//       'your channel id',
//       'your channel name',
//       // 'your channel description',
//       importance: Importance.max,
//       priority: Priority.high,
//       showWhen: false,
//       actions: [
//         AndroidNotificationAction('pause_action', 'Pause'),
//         AndroidNotificationAction('play_action', 'Play'),
//       ],
//     );
//
//     const NotificationDetails platformChannelSpecifics = NotificationDetails(
//       android: androidPlatformChannelSpecifics,
//     );
//
//     await flutterLocalNotificationsPlugin.show(
//       0,
//       title,
//       body,
//       platformChannelSpecifics,
//     );
//   }
// }
