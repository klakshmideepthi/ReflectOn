import * as functions from "firebase-functions/v1";
import {logger} from "firebase-functions/v2";
import fetch from "node-fetch";

// Get OpenAI API key from Firebase Config
async function getOpenAIKey(): Promise<string> {
  const apiKey = functions.config().openai?.key;
  if (!apiKey) {
    logger.error("OpenAI API key is not set in Firebase Config");
    throw new functions.https.HttpsError(
      "failed-precondition",
      "OpenAI API key is not configured. Run: firebase functions:config:set openai.key=YOUR_KEY"
    );
  }
  return apiKey;
}

export const getEphemeralKey = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  try {
    const openaiKey = await getOpenAIKey();

    // Make request to OpenAI API to get ephemeral key
    const response = await fetch("https://api.openai.com/v1/realtime/sessions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${openaiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: data.model || "gpt-4o-realtime-preview-2024-12-17",
        voice: data.voice || "alloy",
      }),
    });

    if (!response.ok) {
      const errorData = await response.text();
      logger.error("OpenAI API error:", errorData);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to generate ephemeral key"
      );
    }

    const responseData = await response.json();

    // Log success (without exposing the key)
    logger.info(`Generated ephemeral key for user ${context.auth.uid}`);

    // Return the ephemeral key data
    return {
      client_secret: responseData.client_secret,
      expires_at: responseData.expires_at
    };

  } catch (error) {
    logger.error("Error in getEphemeralKey:", error);
    throw new functions.https.HttpsError(
      "internal",
      "An error occurred while generating the ephemeral key"
    );
  }
}); 