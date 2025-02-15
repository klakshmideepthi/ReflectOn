import {firestore} from "firebase-admin";
import {defineString} from "firebase-functions/params";
import * as functions from "firebase-functions/v1";
import {UserRecord} from "firebase-functions/v1/auth";
import {logger} from "firebase-functions/v2";

const appVersion = defineString("APP_VERSION", {default: "unknown"});

export const handleUserRecord = functions.auth.user().onCreate(async (user: UserRecord) => {
  try {
    const userId = user.uid;
    const batch = firestore().batch();

    // Create onboarding record
    const onboardingDocRef = firestore().collection("onboarding").doc(userId);
    const onboardingDoc = await onboardingDocRef.get();
    if (!onboardingDoc.exists) {
      batch.set(onboardingDocRef, {
        userId: userId,
        email: user.email || null,
        appVersion: appVersion.value(),
        timestamp: firestore.FieldValue.serverTimestamp(),
        step: 1,
        completed: false,
        lastSignIn: firestore.FieldValue.serverTimestamp(),
      });
    }

    // Create initial user record
    const userDocRef = firestore().collection("users").doc(userId);
    const userDoc = await userDocRef.get();
    if (!userDoc.exists) {
      batch.set(userDocRef, {
        userId: userId,
        email: user.email || null,
        onboardingComplete: false,
        subscriptionStatus: "free",
        focusAreas: [],
        coreMemories: [],
        timestamp: firestore.FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    logger.info(`User records created for user ${userId}`, {
      userId: userId,
      appVersion: appVersion.value(),
    });
  } catch (error) {
    logger.error("Error handling user record:", {
      userId: user.uid,
      error: error instanceof Error ? error.message : "Unknown error",
    });
    throw error;
  }
});

export const updateUserSignIn = functions.auth.user().onCreate(async (user: UserRecord) => {
  try {
    if (!user.uid) return;

    const onboardingDocRef = firestore().collection("onboarding").doc(user.uid);
    await onboardingDocRef.update({
      lastSignIn: firestore.FieldValue.serverTimestamp(),
    });

    logger.info(`Updated sign-in time for user ${user.uid}`);
  } catch (error) {
    logger.error("Error updating sign-in time:", {
      userId: user.uid,
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
});
