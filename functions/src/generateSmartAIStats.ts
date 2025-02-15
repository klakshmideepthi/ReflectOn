import * as functions from "firebase-functions/v1";
import {firestore} from "firebase-admin";
import fetch from "node-fetch";

const logger = functions.logger;

interface SmartAIStats {
  focus_area_1: {
    name: string;
    paragraph: string;
  };
  focus_area_2: {
    name: string;
    paragraph: string;
  };
  emotions: string[];
  key_themes: string[];
  actionable_steps: string[];
}

export const generateSmartAIStats = functions.https.onCall(async (data, context) => {
  // Ensure user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated"
    );
  }

  const {sessionId} = data;
  if (!sessionId) {
    throw new functions.https.HttpsError(
      "invalid-argument", 
      "Session ID is required"
    );
  }

  const db = firestore();
  
  try {
    // Update session status to show we're generating insights
    await db.collection("sessions").doc(sessionId).update({
      status: "initializing"
    });

    // Get session data
    const sessionDoc = await db.collection("sessions").doc(sessionId).get();
    if (!sessionDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Session not found");
    }

    const sessionData = sessionDoc.data();
    if (!sessionData?.transcript) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Session transcript not found"
      );
    }

    // Get user's focus areas
    const userDoc = await db.collection("users").doc(sessionData.userId).get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError("not-found", "User not found");
    }
    const userData = userDoc.data();
    const focusAreas = userData?.focusAreas || [];

    // Get OpenAI API key
    const apiKey = functions.config().openai?.key;
    if (!apiKey) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "OpenAI API key not configured"
      );
    }

    // Prepare prompt for GPT-4
    const prompt = {
      model: "gpt-4o-mini",
      messages: [
        {
          role: "system",
          content: "You are an AI assistant analyzing self-reflection sessions."
        },
        {
          role: "user",
          content: `Analyze this self-reflection session transcript and generate insights. Focus areas: ${focusAreas.join(", ")}\n\nTranscript: ${sessionData.transcript}`
        }
      ],
      functions: [
        {
          name: "generate_insights",
          parameters: {
            type: "object",
            properties: {
              focus_area_1: {
                type: "object",
                properties: {name: {type: "string"}, paragraph: {type: "string"}}
              },
              focus_area_2: {
                type: "object",
                properties: {name: {type: "string"}, paragraph: {type: "string"}}
              },
              emotions: {
                type: "array",
                items: {type: "string"},
                description: "3-5 dominant emotions from the session"
              },
              key_themes: {
                type: "array",
                items: {type: "string"},
                description: "Up to 5 key themes discussed"
              },
              actionable_steps: {
                type: "array",
                items: {type: "string"},
                description: "1-3 specific, actionable steps"
              }
            },
            required: ["focus_area_1", "focus_area_2", "emotions", "key_themes", "actionable_steps"]
          }
        }
      ],
      function_call: {name: "generate_insights"}
    };

    // Call OpenAI API
    const response = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${apiKey}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify(prompt)
    });

    if (!response.ok) {
      throw new Error(`OpenAI API error: ${await response.text()}`);
    }

    const gptResponse = await response.json();
    const insights: SmartAIStats = JSON.parse(
      gptResponse.choices[0].message.function_call.arguments
    );

    // Save insights to Firestore
    await db.collection("sessions").doc(sessionId).update({
      insights: {
        focus_area_1: insights.focus_area_1,
        focus_area_2: insights.focus_area_2,
        emotions: insights.emotions,
        key_themes: insights.key_themes,
        actionable_steps: insights.actionable_steps
      },
      status: "insights_generated",
      updatedAt: firestore.FieldValue.serverTimestamp()
    });

    // Trigger assessment scores generation
    // TODO: Implement this after creating generateAssessmentScores function

    return insights;

  } catch (error: unknown) {
    // Update session status to failed if there's an error
    await db.collection("sessions").doc(sessionId).update({
      status: "insights_generation_failed",
      error: error instanceof Error ? error.message : "An unknown error occurred"
    });

    logger.error("Error generating insights:", error);
    throw new functions.https.HttpsError(
      "internal",
      error instanceof Error ? error.message : "Failed to generate insights"
    );
  }
}); 