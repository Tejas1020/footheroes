import 'dart:async';
import 'package:dart_appwrite/dart_appwrite.dart';

Future<void> main(final context) async {
  final client = Client()
    .setEndpoint('https://fra.cloud.appwrite.io/v1')
    .setProject(context.env['APPWRITE_FUNCTION_PROJECT_ID'])
    .setKey(context.env['APPWRITE_API_KEY']);

  final db = Databases(client);
  final now = DateTime.now();

  // Find pending requests where either:
  // - createdAt is older than 24h, OR
  // - match startTime is within 2h
  final result = await db.listDocuments(
    databaseId: context.env['DATABASE_ID']!,
    collectionId: context.env['JOIN_REQUESTS_COLLECTION_ID']!,
    queries: [
      Query.equal('status', 'pending'),
    ],
  );

  var expiredCount = 0;
  for (final doc in result.documents) {
    final createdAt = DateTime.parse(doc.data['createdAt']);
    final matchId = doc.data['matchId'];

    final matchDoc = await db.getDocument(
      databaseId: context.env['DATABASE_ID']!,
      collectionId: context.env['MATCHES_COLLECTION_ID']!,
      documentId: matchId,
    );
    final startTime = DateTime.parse(matchDoc.data['matchDate']);
    final twoHoursBefore = startTime.subtract(const Duration(hours: 2));

    if (now.isAfter(createdAt.add(const Duration(hours: 24))) ||
        now.isAfter(twoHoursBefore)) {
      await db.updateDocument(
        databaseId: context.env['DATABASE_ID']!,
        collectionId: context.env['JOIN_REQUESTS_COLLECTION_ID']!,
        documentId: doc.$id,
        data: {'status': 'expired'},
      );
      expiredCount++;
    }
  }

  context.log('Expired $expiredCount pending join requests');
}
