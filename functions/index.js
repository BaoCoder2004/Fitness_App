const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Email sending removed per request; function now no-ops.
exports.onUnlockRequestStatusChange = functions.firestore
  .document('unlock_requests/{requestId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (!before || !after) return null;
    if (before.status === after.status) return null;
    if (before.status !== 'pending') return null;
    if (!['approved', 'rejected'].includes(after.status)) return null;

    console.log('[unlock-email] Email sending disabled; status change observed', {
      requestId: context.params.requestId,
      status: after.status,
    });
    return null;
  });

