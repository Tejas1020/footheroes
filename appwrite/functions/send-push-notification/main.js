const sdk = require('node-appwrite');

module.exports = async (context) => {
  const client = new sdk.Client();
  client
    .setEndpoint(process.env.APPWRITE_FUNCTION_API_ENDPOINT)
    .setProject(process.env.APPWRITE_FUNCTION_PROJECT_ID)
    .setKey(process.env.APPWRITE_FUNCTION_API_KEY);

  const databases = new sdk.Databases(client);
  const messaging = new sdk.Messaging(client);

  const databaseId = process.env.APPWRITE_DATABASE_ID;
  const matchesCollectionId = process.env.MATCHES_COLLECTION_ID;
  const joinRequestsCollectionId = process.env.JOIN_REQUESTS_COLLECTION_ID;
  const notificationsCollectionId = process.env.NOTIFICATIONS_COLLECTION_ID;

  // Parse event payload
  let eventData = {};
  try {
    if (context.req.bodyRaw) {
      eventData = JSON.parse(context.req.bodyRaw);
    }
  } catch (e) {
    context.error('Failed to parse event body:', e);
    return context.res.json({ success: false, error: 'Invalid body' }, 400);
  }

  const document = eventData;
  const eventHeader = context.req.headers['x-appwrite-event'] || '';

  try {
    // Handle new join request
    if (eventHeader.includes('.documents.*.create')) {
      const matchId = document.matchId;
      const requesterUid = document.requesterUid;

      if (!matchId) {
        return context.res.json({ success: false, error: 'Missing matchId' }, 400);
      }

      const match = await databases.getDocument(
        databaseId,
        matchesCollectionId,
        matchId
      );

      const creatorUid = match.createdBy;
      if (!creatorUid || creatorUid === requesterUid) {
        return context.res.json({ success: true, skipped: true });
      }

      await createNotification(
        databases,
        databaseId,
        notificationsCollectionId,
        {
          title: 'New Join Request',
          body: `A player wants to join your ${match.format} match at ${match.venueName || 'your venue'}.`,
          type: 'join_request',
          priority: 'normal',
          targetUserId: creatorUid,
          relatedId: document.$id,
          relatedType: 'joinRequest',
        }
      );

      return context.res.json({ success: true, action: 'notified_creator' });
    }

    // Handle join request status change
    if (eventHeader.includes('.documents.*.update')) {
      const status = document.status;
      const requesterUid = document.requesterUid;
      const matchId = document.matchId;

      if (!requesterUid || !matchId) {
        return context.res.json({ success: false, error: 'Missing fields' }, 400);
      }

      const match = await databases.getDocument(
        databaseId,
        matchesCollectionId,
        matchId
      );

      if (status === 'approved') {
        await createNotification(
          databases,
          databaseId,
          notificationsCollectionId,
          {
            title: 'Request Approved',
            body: `You have been approved to join the ${match.format} match at ${match.venueName || 'the venue'}.`,
            type: 'request_approved',
            priority: 'normal',
            targetUserId: requesterUid,
            relatedId: document.$id,
            relatedType: 'joinRequest',
          }
        );
        return context.res.json({ success: true, action: 'notified_approved' });
      }

      if (status === 'declined') {
        await createNotification(
          databases,
          databaseId,
          notificationsCollectionId,
          {
            title: 'Request Declined',
            body: `Your request to join the ${match.format} match was declined.`,
            type: 'request_declined',
            priority: 'normal',
            targetUserId: requesterUid,
            relatedId: document.$id,
            relatedType: 'joinRequest',
          }
        );
        return context.res.json({ success: true, action: 'notified_declined' });
      }

      return context.res.json({ success: true, skipped: true });
    }

    return context.res.json({ success: true, skipped: true });
  } catch (e) {
    context.error('Function error:', e);
    return context.res.json({ success: false, error: e.message }, 500);
  }
};

async function createNotification(databases, databaseId, collectionId, data) {
  const now = new Date().toISOString();
  await databases.createDocument(
    databaseId,
    collectionId,
    sdk.ID.unique(),
    {
      title: data.title,
      body: data.body,
      type: data.type,
      priority: data.priority,
      isRead: false,
      createdAt: now,
      targetUserId: data.targetUserId,
      relatedId: data.relatedId,
      relatedType: data.relatedType,
    }
  );
}
