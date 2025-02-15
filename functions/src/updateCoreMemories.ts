import * as functions from "firebase-functions/v1";
import {firestore} from "firebase-admin";
import fetch from "node-fetch";

/**
 * The shape of the request data the client passes to this function:
 * {
 *   transcript: string
 * }
 */
export const updateCoreMemories = functions.https.onCall(async (data, context) => {
  // 1) Ensure user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Must be authenticated to update core memories."
    );
  }

  const userId = context.auth.uid;
  const transcript = data.transcript;
  if (typeof transcript !== "string" || !transcript.trim()) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "A valid transcript is required."
    );
  }

  // 2) Retrieve your OpenAI API key from Firebase Config
  const openaiApiKey = functions.config().openai?.key;
  if (!openaiApiKey) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Missing OpenAI API key in Firebase config. Provide it via `firebase functions:config:set openai.key=YOUR_KEY`"
    );
  }

  try {
    // 3) Load the user's existing (old) coreMemories
    const db = firestore();
    const userRef = db.collection("users").doc(userId);
    const userSnap = await userRef.get();
    if (!userSnap.exists) {
      throw new functions.https.HttpsError("not-found", "User document not found.");
    }

    const userData = userSnap.data() || {};
    const oldMemories = Array.isArray(userData.coreMemories) 
      ? userData.coreMemories 
      : [];

    // 4) Prepare GPT prompt. We show both oldMemories and the new transcript to GPT so it can unify them.
    const systemPrompt = {
      role: "system",
      content: `
You are a specialized AI that merges old core memories and newly discovered ones from a conversation transcript.
Your output MUST be strictly a JSON array of strings, each string is a "core memory."
If none found, return an empty array: []
Deduplicate any repeats.`
    };

    const userPrompt = {
      role: "user",
      content: `
Here are the user's old core memories (JSON array):
${JSON.stringify(oldMemories, null, 2)}

Here is the new transcript to extract additional "core memories":
${transcript}

Return a final JSON array that merges old and new core memories, removing duplicates.`
    };

    // 5) Send request to OpenAI's Chat Completion API (gpt-4o or whichever model you prefer)
    const body = {
      model: "gpt-4o-mini", // or "gpt-4o-realtime-preview-2024-12-17" etc.
      messages: [systemPrompt, userPrompt],
      temperature: 0.3
    };

    const response = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${openaiApiKey}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify(body)
    });

    if (!response.ok) {
      const errText = await response.text();
      throw new Error(`OpenAI API responded with error: ${errText}`);
    }

    const jsonResp: any = await response.json();
    // The assistant's text:
    const assistantMessage = jsonResp?.choices?.[0]?.message?.content?.trim();
    if (!assistantMessage) {
      throw new Error("No content returned from GPT model.");
    }

    // 6) Attempt to parse the assistant’s text as a JSON array of core memories.
    let newCoreMemories: string[] = [];
    try {
      newCoreMemories = JSON.parse(assistantMessage);
    } catch (e) {
      // If not valid JSON, fallback to empty
      functions.logger.warn(
        "Failed to parse GPT output as JSON array. Full text:", 
        assistantMessage
      );
      newCoreMemories = [];
    }

    // Ensure we actually have an array, or fallback
    if (!Array.isArray(newCoreMemories)) {
      newCoreMemories = [];
    }

    // 7) Merge & deduplicate with the old memories
    const mergedMemories = Array.from(
      new Set([...oldMemories, ...newCoreMemories])
    );

    // 8) Update Firestore
    await userRef.update({coreMemories: mergedMemories});

    // 9) Return success
    return {
      success: true,
      newMemories: newCoreMemories,
      totalMemories: mergedMemories.length,
    };

  } catch (error: any) {
    functions.logger.error("Error updating core memories with GPT:", error);
    throw new functions.https.HttpsError(
      "internal",
      error?.message || "Unknown error"
    );
  }
});
