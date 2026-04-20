import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

export const deleteUser = functions.https.onCall(async (data, context) => {

  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Not logged in");
  }

  const uid = data.uid;

  await admin.auth().deleteUser(uid);

  await admin.firestore().collection("users").doc(uid).delete();

  return { success: true };

});