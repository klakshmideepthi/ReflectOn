import * as functions from "firebase-functions/v1";
import {firestore} from "firebase-admin";
import {logger} from "firebase-functions/v2";

interface OnboardingData {
  selectedFocusAreas: string[];
  age: number;
  gender: string;
  baselineAnswers: Record<string, any>;
  reminderTime: string;
}

export const storeOnboardingData = functions.https.onCall(async (data: OnboardingData, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  const userId = context.auth.uid;

  try {
    // Validate input data
    if (!data.selectedFocusAreas || 
        data.selectedFocusAreas.length !== 2 ||
        !data.age ||
        !data.gender ||
        !data.baselineAnswers ||
        !data.reminderTime) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing or invalid onboarding data."
      );
    }

    // Get Firestore instance
    const db = firestore();

    // Create a batch write operation
    const batch = db.batch();

    // Update user document
    const userRef = db.collection("users").doc(userId);
    batch.set(userRef, {
      userId,
      focusAreas: data.selectedFocusAreas,
      age: data.age,
      gender: data.gender,
      reminderTime: data.reminderTime,
      onboardingComplete: false,
      subscriptionStatus: "free", // Default status
      coreMemories: [],
    }, {merge: true});

    // Store baseline answers in subcollection
    const timestamp = firestore.FieldValue.serverTimestamp();
    for (const [questionId, answer] of Object.entries(data.baselineAnswers)) {
      const answerRef = userRef.collection("baselineAnswers").doc();
      batch.set(answerRef, {
        questionId,
        answer,
        timestamp,
      });
    }

    // Commit the batch
    await batch.commit();

    logger.info(`Stored onboarding data for user ${userId}`, {
      userId,
      focusAreas: data.selectedFocusAreas,
    });

    return {success: true};
  } catch (error) {
    logger.error("Error storing onboarding data:", {
      userId,
      error: error instanceof Error ? error.message : "Unknown error",
    });
    throw new functions.https.HttpsError(
      "internal",
      "An error occurred while storing onboarding data."
    );
  }
}); 