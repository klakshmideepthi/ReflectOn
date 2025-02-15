import * as functions from "firebase-functions/v1";
import {firestore} from "firebase-admin";
import {logger} from "firebase-functions/v2";

export const saveFeedback = functions.https.onCall(async (data, context) => {
  // Ensure user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Must be authenticated to provide feedback."
    );
  }

  const userId = context.auth.uid;

  // Validate input data
  if (!data.rating || !["thumbs_up", "thumbs_down"].includes(data.rating)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Invalid rating value"
    );
  }

  // Validate sessionId
  if (!data.sessionId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "sessionId is required"
    );
  }

  // If rating is thumbs_down, comment is required
  if (data.rating === "thumbs_down" && (!data.comment || !data.comment.trim())) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Comment is required for negative feedback"
    );
  }

  try {
    const db = firestore();

    // Create feedback document
    const feedbackRef = db.collection("feedback").doc();

    await feedbackRef.set({
      userId: userId,
      sessionId: data.sessionId,
      rating: data.rating,
      comment: data.rating === "thumbs_down" ? data.comment : "",
      timestamp: firestore.FieldValue.serverTimestamp(),
    });

    logger.info(`Feedback saved for user ${userId}`, {
      feedbackId: feedbackRef.id,
      rating: data.rating,
      sessionId: data.sessionId
    });

    return {
      success: true,
      feedbackId: feedbackRef.id
    };

  } catch (error) {
    logger.error("Error saving feedback:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Failed to save feedback"
    );
  }
});