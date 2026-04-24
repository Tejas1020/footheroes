const sdk = require('node-appwrite');

module.exports = async (context) => {
  const client = new sdk.Client();
  client
    .setEndpoint(process.env.APPWRITE_FUNCTION_API_ENDPOINT)
    .setProject(process.env.APPWRITE_FUNCTION_PROJECT_ID)
    .setKey(process.env.APPWRITE_FUNCTION_API_KEY);

  const databases = new sdk.Databases(client);
  const databaseId = process.env.APPWRITE_DATABASE_ID;
  const joinRequestsCollectionId = process.env.JOIN_REQUESTS_COLLECTION_ID;
  const notificationsCollectionId = process.env.NOTIFICATIONS_COLLECTION_ID;

  // Cutoff: requests older than 24 hours are stale
  const cutoff = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();

  context.log('Running expiry job. Cutoff:', cutoff);

  try {
    let offset = 0;
    const limit = 100;
    let totalExpired = 0;

    while (true) {
      const result = await databases.listDocuments(
        databaseId,
        joinRequestsCollectionId,
        [
          sdk.Query.equal('status', 'pending'),
          sdk.Query.lessThan('createdAt', cutoff),
          sdk.Query.limit(limit),
          sdk.Query.offset(offset),
        ]
      );

      const docs = result.documents;
      if (docs.length === 0) break;

      for (const doc of docs) {
        await databases.updateDocument(
          databaseId,
          joinRequestsCollectionId,
          doc.$id,
          {
            status: 'expired',
            respondedAt: new Date().toISOString(),
          }
        );

        // Notify requester
        if (doc.requesterUid && notificationsCollectionId) {
          try {
            await databases.createDocument(
              databaseId,
              notificationsCollectionId,
              sdk.ID.unique(),
              {
                title: 'Join Request Expired',
                body: 'Your request to join the match has expired.',
                type: 'request_expired',
                priority: 'normal',
                isRead: false,
                createdAt: new Date().toISOString(),
                targetUserId: doc.requesterUid,
                relatedId: doc.$id,
                relatedType: 'joinRequest',
              }
            );
          } catch (e) {
            context.error('Failed to create expiry notification:', e);
          }
        }

        totalExpired++;
      }

      if (docs.length < limit) break;
      offset += limit;
    }

    context.log('Expired', totalExpired, 'requests');
    return context.res.json({ success: true, expired: totalExpired });
  } catch (e) {
    context.error('Expiry job failed:', e);
    return context.res.json({ success: false, error: e.message }, 500);
  }
};
