import 'dart:io';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/sendgrid.dart';

void main(List<String> arguments) {
  final env = Platform.environment;
  final username = env['SENDGRID_USERNAME'] ?? '';
  final password = env['SENDGRID_PASSWORD'] ?? '';

  final projectId = env['APPWRITE_FUNCTION_PROJECT_ID'] ?? '';
  final endpont = env['APPWRITE_ENDPOINT'] ?? '';
  final key = env['APPWRITE_KEY'] ?? '';
  final collectionId = env['COLLECTION_ID'] ?? '';

  Client client =
      Client().setEndpoint(endpont).setProject(projectId).setKey(key);
  final users = Users(client);

  users.list().then((res) async {
    final usersList = res.data['users'];
    for (var user in usersList) {
      final String? email = user['email'];
      if (email != null && email.isNotEmpty) {
        try {
          if (!await hasIntakes(
            client: client,
            collectionId: collectionId,
            userId: user['\$id'],
          )) {
            //send email
            await sendEmail(username, password, email);
            print('email sent');
          }
        } catch (error) {
          if (error is AppwriteException) {
            print(error.message);
            rethrow;
          }
          rethrow;
        }
      }
    }
  }).catchError((error) {
    if (error is AppwriteException) {
      print(error.message);
      throw error;
    } else {
      print(error);
      throw error;
    }
  });
}

Future sendEmail(String username, String password, String email) async {
  final smtpServer = sendgrid(username, password);

  final message = Message()
    ..from = Address('damodar@appwrite.io', 'Damodar')
    ..recipients.add(email)
    ..subject = 'Reminder to drink water'
    ..text =
        'Hey, how are you doing?\nThis is just a simple reminder to drink water.\nStay Hydrated, Stay Healthy';
  return send(message, smtpServer);
}

Future<bool> hasIntakes({
  required Client client,
  required String collectionId,
  required String userId,
}) async {
  final _db = Database(client);
  var date = DateTime.now();
  final from = DateTime(date.year, date.month, date.day, 0);
  final to = DateTime(date.year, date.month, date.day, 23, 59, 59);
  final res = await _db.listDocuments(
      collectionId: collectionId,
      filters: [
        'user_id=$userId',
        'date>=${from.millisecondsSinceEpoch}',
        'date<=${to.millisecondsSinceEpoch}'
      ],
      orderField: 'date',
      orderType: OrderType.desc);
  print("Total: ${res.data['sum']}");
  return res.data['sum'] > 0;
}
