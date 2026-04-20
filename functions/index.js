// functions/index.js
const { onRequest } = require('firebase-functions/v2/https');
const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const logger = require('firebase-functions/logger');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();
const STATS_DOC = db.doc('stats/aggregates');

// --- ensure stats doc exists (idempotent) ---
async function ensureStatsDoc() {
  await STATS_DOC.set(
    {
      communityOpenAlerts: admin.firestore.FieldValue.increment(0),
      patrolAckCount: admin.firestore.FieldValue.increment(0),
      policeAckCount: admin.firestore.FieldValue.increment(0),
      responseCount: admin.firestore.FieldValue.increment(0),
      sumResponseSecs: admin.firestore.FieldValue.increment(0),
      medianResponseSecs: 0, // we store an avg here to keep UI happy
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
}

// --- UTIL: seconds between two Firestore Timestamps (fallbacks to 0) ---
function diffSeconds(a, b) {
  if (!a || !b) return 0;
  const ms = a.toMillis() - b.toMillis();
  return Math.max(0, Math.round(ms / 1000));
}

/**
 * ALERT CREATE
 * Increments communityOpenAlerts on each new alert.
 * Expects alert doc has createdAt (serverTimestamp) – but we don't require it to increment.
 */
exports.onAlertCreate = onDocumentCreated(
  { region: 'us-central1' },
  'alerts/{alertId}',
  async (event) => {
    try {
      await ensureStatsDoc();
      await STATS_DOC.update({
        communityOpenAlerts: admin.firestore.FieldValue.increment(1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      logger.info('Stats: communityOpenAlerts +1', { alertId: event.params.alertId });
    } catch (err) {
      logger.error('onAlertCreate failed', { err });
    }
  }
);

/**
 * ALERT UPDATE
 * Detects status changes and first acknowledgements to:
 * - decrement communityOpenAlerts (first time it is ack/resolved)
 * - increment patrolAckCount / policeAckCount
 * - accumulate response time (ackAt - createdAt)
 */
exports.onAlertUpdate = onDocumentUpdated(
  { region: 'us-central1' },
  'alerts/{alertId}',
  async (event) => {
    const before = event.data.before.data() || {};
    const after = event.data.after.data() || {};

    const prevStatus = (before.status || 'open').toString();
    const newStatus  = (after.status  || 'open').toString();

    // Detect first acknowledgement (we guard with a boolean flag on the doc)
    const hadAck = !!before._statsAcked;
    const hasAckNow = !!after._statsAcked ||
                      newStatus === 'ack' || newStatus === 'resolved';

    // If we didn’t ack before but we are acked now, do counters once.
    if (!hadAck && hasAckNow) {
      const ackRole = (after.ackRole || '').toString().toLowerCase(); // 'patrol' | 'police' | ''
      const ackAt = after.ackAt || after.updatedAt || event.data.after.updateTime; // prefer app-set ackAt
      const createdAt = after.createdAt || before.createdAt || event.data.before.createTime;

      const responseSecs = diffSeconds(ackAt, createdAt);

      try {
        await ensureStatsDoc();

        // atomically update counters
        const updates = {
          communityOpenAlerts: admin.firestore.FieldValue.increment(-1),
          responseCount: admin.firestore.FieldValue.increment(1),
          sumResponseSecs: admin.firestore.FieldValue.increment(responseSecs),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        if (ackRole === 'patrol') {
          updates.patrolAckCount = admin.firestore.FieldValue.increment(1);
        } else if (ackRole === 'police') {
          updates.policeAckCount = admin.firestore.FieldValue.increment(1);
        }

        // Apply stats updates
        await STATS_DOC.update(updates);

        // Recompute avg into medianResponseSecs (simple & lock-free)
        await db.runTransaction(async (tx) => {
          const snap = await tx.get(STATS_DOC);
          const d = snap.data() || {};
          const cnt = Number(d.responseCount || 0);
          const sum = Number(d.sumResponseSecs || 0);
          const avg = cnt > 0 ? Math.round(sum / cnt) : 0;
          tx.update(STATS_DOC, { medianResponseSecs: avg, updatedAt: admin.firestore.FieldValue.serverTimestamp() });
        });

        // Mark the alert so we don't double-count if it’s edited again
        await event.data.after.ref.set({ _statsAcked: true }, { merge: true });

        logger.info('Stats updated on first ack', {
          alertId: event.params.alertId,
          ackRole,
          responseSecs,
        });
      } catch (err) {
        logger.error('onAlertUpdate failed', { err });
      }
    }

    // If there was no "first ack" but status flipped back to open → do nothing.
    // If you want to handle "re-opened alerts", you can add logic here.
  }
);

// ---------------- Existing HTTP functions (unchanged) ----------------
// status, validateCamera, panicFanout ... keep your current implementations.
