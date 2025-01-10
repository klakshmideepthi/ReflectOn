// File: functions/src/index.ts
import * as functions from "firebase-functions/v1";
import {firestore} from "firebase-admin";
import fetch from "node-fetch";

const logger = functions.logger;

// Define the shape of the data your client sends to getEphemeralKey
interface GetEphemeralKeyData {
  model?: string;
  voice?: string;
}

// Define the shape of the response you get back from OpenAI Realtime 
interface OpenAIRealtimeResponse {
  client_secret?: {
    value?: string;
  };
}

/**
 * getEphemeralKey
 * 
 * Callable Cloud Function that fetches an ephemeral key from OpenAI Realtime.
 */
export const getEphemeralKey = functions.https.onCall(async (data, context) => {
  const requestData = data as GetEphemeralKeyData;
  
  // Ensure user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated to get ephemeral key."
    );
  }

  // Get OpenAI API key from Firebase config
  const apiKey = functions.config().openai?.key;
  if (!apiKey) {
    logger.error("OpenAI API key is not set in Firebase Config");
    throw new functions.https.HttpsError(
      "failed-precondition",
      "OpenAI API key is not configured. Run: firebase functions:config:set openai.key=YOUR_KEY"
    );
  }

  // Extract model and voice from the request data
  const model = requestData.model || "gpt-4o-realtime-preview-2024-12-17";
  const voice = requestData.voice || "alloy";

  try {
    // Make request to OpenAI Realtime "sessions" endpoint
    const response = await fetch("https://api.openai.com/v1/realtime/sessions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        model,
        voice
      })
    });

    if (!response.ok) {
      const errorData = await response.text();
      logger.error("OpenAI API error:", errorData);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to generate ephemeral key from OpenAI"
      );
    }

    const openAIResponse = (await response.json()) as OpenAIRealtimeResponse;
    logger.info(`Generated ephemeral key for user ${context.auth.uid}`, {
      model,
      voice
    });

    return openAIResponse;

  } catch (error) {
    logger.error("Error in getEphemeralKey:", error);
    throw new functions.https.HttpsError(
      "internal",
      "An error occurred while generating the ephemeral key."
    );
  }
});

// Define the shape of the data your client sends to transcribeAudio
export interface TranscribeAudioRequest {
  sessionId: string;
  userTranscript: string;
  assistantTranscript: string;
  userId: string;
  timestamp: number;
}

/**
 * transcribeAudio
 * 
 * Callable Cloud Function that saves transcripts to Firestore.
 */
export const transcribeAudio = functions.https.onCall(async (data, context) => {
  logger.info("transcribeAudio called with data:", {
    data,
    auth: context.auth ? "authenticated" : "not authenticated"
  });

  // Ensure user is authenticated
  if (!context.auth) {
    logger.error("Authentication failed - no auth context");
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  const requestData = data as TranscribeAudioRequest;
  const {sessionId, userTranscript, assistantTranscript, userId, timestamp} = requestData;

  // Log authentication details
  logger.info("Authentication details:", {
    callerUid: context.auth.uid,
    requestUserId: userId,
    sessionId
  });

  // Validate input
  if (!sessionId || (!userTranscript || !assistantTranscript) || !userId) {
    logger.error("Missing required data", {
      sessionId, 
      hasUserTranscript: !!userTranscript,
      hasAssistantTranscript: !!assistantTranscript,
      userId
    });
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Missing required data."
    );
  }

  // Ensure the userId in the data matches the authenticated user's uid
  if (userId !== context.auth.uid) {
    logger.error("User ID mismatch", {
      providedUserId: userId,
      authenticatedUserId: context.auth.uid
    });
    throw new functions.https.HttpsError(
      "permission-denied",
      "User ID does not match authenticated user."
    );
  }

  const db = firestore();
  const sessionRef = db.collection("sessions").doc(sessionId);
  const userRef = db.collection("users").doc(userId);

  try {
    // First check if user exists
    const userDoc = await userRef.get();
    if (!userDoc.exists) {
      logger.error("User document not found", {userId});
      throw new functions.https.HttpsError(
        "not-found",
        "User document not found"
      );
    }

    // Create a batch write
    const batch = db.batch();

    // Update session document
    batch.set(sessionRef, {
      userId,
      userTranscript,
      assistantTranscript,
      status: "completed",
      timestamp: firestore.Timestamp.fromMillis(timestamp),
      endTime: firestore.FieldValue.serverTimestamp(),
      createdAt: firestore.FieldValue.serverTimestamp()
    }, {merge: true});

    // Also store in user's transcripts collection
    const transcriptRef = userRef.collection("transcripts").doc();
    batch.set(transcriptRef, {
      sessionId,
      userTranscript,
      assistantTranscript,
      timestamp: firestore.Timestamp.fromMillis(timestamp)
    });

    // Commit both writes
    await batch.commit();

    logger.info("Successfully saved transcripts", {
      sessionId,
      userId,
      status: "completed"
    });

    return {success: true, sessionId, status: "completed"};

  } catch (error) {
    logger.error("Error saving transcripts:", {
      sessionId,
      userId,
      error: error instanceof Error ? error.message : "Unknown error",
      stack: error instanceof Error ? error.stack : null
    });

    // If there's an error, mark the session as failed
    await sessionRef.set({
      status: "failed",
      endTime: firestore.FieldValue.serverTimestamp(),
      error: error instanceof Error ? error.message : "Unknown error",
      errorStack: error instanceof Error ? error.stack : null
    }, {merge: true});

    throw new functions.https.HttpsError(
      "internal",
      "An error occurred while saving the transcripts."
    );
  }
});