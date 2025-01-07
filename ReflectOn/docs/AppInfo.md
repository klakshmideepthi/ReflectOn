Self-Reflection AI Assistant App Concept

**App Documentation Version 0.1.1 (Draft - In Progress)**

**Core Purpose**

The app provides a user-friendly and accessible self-reflection experience through an AI-powered conversational interface. It addresses the challenge of making self-reflection a daily habit by offering engaging and personalized sessions that encourage users to explore their thoughts, emotions, and experiences. The app aims to make self-reflection an enjoyable and rewarding practice, leading to personal growth and improved well-being.

**User Onboarding Process**

1. **Splash Screen:** The app opens with a simple splash screen (1-2 seconds).
2. **Introduction with Illustrations:** A page follows with three illustrations explaining the app's purpose. Users tap "Tap to Continue" to proceed.
3. **"Get Started for Free" or "Login":** Users are presented with two options: "Get Started for Free" and "Log in."
    - "Get Started for Free": Proceeds to the Welcome Page (Step 5).
    - "Log in": Proceeds to the Account Setup page (Step 14).
4. **Back Button Behavior:** If the user clicks the back button before successfully authenticating, they are taken back to the "Get Started for Free" or "Login" page. The onboarding step is reset to 3.
5. **Welcome Page:** A brief welcome message: "Answer a few questions to personalize your experience." "Tap to Continue" button advances to the next step.
6. **Focus Areas Selection:** Users choose two focus areas from the following options, each with a title and illustration. The choices are stored temporarily within the app:
    - Emotional Awareness
    - Stress Reduction
    - Personal Growth
    - Strengths and Weaknesses
    - Better Decision-Making
    - Improved Relationships
    - Positive Habits
    - Gratitude
    - Self-Compassion
    - Mindfulness
    - Goal Setting
7. The "Tap to Continue" button activates once two are selected. (All options, including titles, descriptions, and illustrations, are predefined and stored within the app.)
8. **Self-Promotion Page:** A promotional page highlights the benefits of self-reflection with 2-3 short statements and illustrations. These are predefined and stored within the app:
    - "Self-reflection improves cognitive ability by [X]%"
    - "Self-reflection enhances personal relationships."
    - "Self-reflection boosts productivity and well-being."
9. **Basic Questions:** Users are asked basic information like age and gender on separate pages. The answers are stored temporarily within the app.
10. **Baseline Questions:** Start with 2-3 unique questions (out of a total of 10) to establish a baseline. These questions are predefined and stored within the app. The answers are stored temporarily within the app. (Note: Baseline data is collected for long-term progress tracking but is not used in the immediate Self-Reflection Loop processing.)
11. **Self-Promotion Page:** Another promotional page highlights the app's success with user testimonials. These are predefined and stored within the app.
12. **Remaining Questions:** Continue with the remaining baseline questions (predefined and stored within the app) to gather essential information. The answers are stored temporarily within the app.
13. **Reminder Setup:** Users set a daily reminder for self-reflection, selecting a time using a time picker. The "Tap to Continue" button appears after setting the reminder. The chosen time is stored temporarily within the app.
14. **Notification Permission:** The app requests permission to send notifications.
15. **Account Setup:** Users are presented with options to log in using "Continue with Apple" or "Continue with Google."
    - **Back Button Behavior:** If the user clicks the back button before successfully authenticating, they are taken back to the "Get Started for Free" or "Login" page. The onboarding step is reset to 3.
    - **Upon successful login:**
        - If the user is an existing user and has completed onboarding previously, they are taken directly to the Home Screen (Step 17).
        - If the user is new or has not completed onboarding, all temporarily stored data from the onboarding process is saved to Firestore under the user's unique ID, and they proceed to step 15. If the user closes the app before completing this step, their progress in the onboarding is reset.
16. **Paywall:** Users see a paywall page with subscription options. Clicking the "X" button skips the subscription.
17. **First Self-Reflection Loop:** Users are immediately taken into their first self-reflection loop to understand the core experience. Upon completion, the user is marked as having completed onboarding.
18. **Home Screen:** After completing the first loop, users are taken to the home screen.

**Home Screen Layout**

- **Dynamic Content Section (Top):**
    - Rotating display (10-20 second intervals).
    - Shows inspirational quotes.
    - Displays personalized insights from previous sessions.
    - Smooth transitions between content.
    - Content can be either LLM-generated or predefined, depending on user preferences and data availability.
- **Stats & Analysis Widget:**
    - Visual representation of progress.
    - Click expands to detailed stats page.
    - Shows key metrics and improvements.
    - Historical data view with trends and patterns.
    - Detailed insights into previous sessions.
    - Graphs and widgets displaying progress across all factors.
- **Streak Visualization:**
    - Week view with 7 circles.
    - Current day highlighted in a distinct color.
    - Completed days visually indicated (glowing effect).
    - Visual indication when streak is lost.
    - Encourages continuous engagement.
    - Highlights completed days with a glowing effect or distinct color.
    - Indicates lost streaks with visual changes to motivate re-engagement.
- **Let's Self-Reflect Button (Bottom):**
    - Primary call-to-action for starting a new loop.
    - Clear, inviting design.

**Self-Reflection Loop**

- **Conversational LLM**
    - Conducts interactive self-reflection sessions.
    - Maintains natural, flowing conversation.
    - Guided by prompts to gather necessary information.
    - Adapts based on user responses and engagement.
    - Concludes sessions efficiently based on gathered insights.
- **Smart AI Stats LLM**
    - Generates insights and summaries of the user's reflections.
    - Provides meaningful, LLM-powered personalized content for the home screen's dynamic widget.
- **Assessment LLM**
    - Analyzes session transcripts and provides scoring.
    - Processes multiple data sources:
        - Current session transcript.
        - Up to 3 previous session transcripts with timestamps.
        - Baseline data from initial setup. (Note: Baseline data is collected during onboarding but not used in Smart AI Stats generation for the current session. It's used for long-term progress tracking.)
    - Evaluates responses against predefined factor questions.
    - Generates numerical scores and progress assessments.

**The Flow of Self-Reflection Loop**

1. **Initiation:**
    - User starts the session by clicking "Let’s Self-Reflect" (or automatically initiated after the paywall during onboarding).
    - The app transitions to a "Preparation" page.
    - In the background:
        - The app creates a new session document in Firestore (sessions/{sessionId}) with initial data: userId, startTime, and status: "initializing".
        - The app calls the getEphemeralKey Cloud Function to obtain a short-lived, limited-scope OpenAI API key for the upcoming Realtime API interaction.
2. **Preparation:**
    - A page displays with the message, "Take a deep breath and start when you are ready."
    - A "Tap to Continue" button is available at the bottom of the page.
    - User taps "Tap to Continue" to proceed.
3. **Interactive Reflection (Conversation Page):**
    - The app establishes a WebRTC connection directly to the OpenAI Realtime API, using the ephemeral API key for authentication.
    - Initial instructions, including the hardcoded system_prompt, are sent directly to the API via the WebRTC data channel.
    - Audio recording begins, and the session status in Firestore is updated to "in progress."
    - Flexible duration (up to 5 minutes) based on conversation depth.
    - AI guides discussion to cover necessary areas, focusing on the user's chosen focus areas.
    - Real-time transcription of the AI's responses is displayed on the screen (using response.text.delta events received via WebRTC).
    - At the 3-minute mark, the client sends a signal to the Realtime API (via the data channel) prompting the AI to begin wrapping up the conversation.
    - At the 5-minute mark, the client sends a signal to the Realtime API to gracefully end the session.
    - The Realtime API ends the session.
    - The client:
        - Stops recording audio.
        - Closes the WebRTC connection.
        - Disables the phone's back button functionality.
        - Updates endTime and status to "completed" in sessions/{sessionId}.
        - Initiates the transcription process by calling the transcribeAudio Cloud Function, sending the recorded audio file directly in the request body.
        - Transitions to the Smart AI Stats Page.
    - **User has the option to cancel by clicking "x" which will take them to the home screen.** If cancelled:
        - The client stops recording audio.
        - Closes the WebRTC connection.
        - Updates endTime and status to "cancelled" in sessions/{sessionId}.
        - Transitions to the Home Screen.
4. **Smart AI Insights (Smart AI Stats Page):**
    - A new page displays with a loading indicator or message while the generateSmartAIStats Cloud Function analyzes the session transcript and generates insights.
    - The transcribeAudio function, upon completion of the transcription and storing it in Firestore, triggers the generateSmartAIStats function.
    - The generateSmartAIStats function:
        - Retrieves the transcript and the user's focus areas from Firestore.
        - Constructs a prompt for the Smart AI Stats LLM, including the transcript and focus areas.
        - Sends the prompt to the Smart AI Stats LLM.
        - Receives the generated insights (structured JSON).
        - Updates sessions/{sessionId}: stores insights, changes status to "insights_generated".
        - Triggers the generateAssessmentScores function.
    - The generateSmartAIStats function structures its output as a JSON object, designed to populate the four widgets on this page:
        - **Focus Area Reflection:** Provides a short paragraph for each focus area, explaining how the session addressed it.
        - **Emotional Landscape:** Identifies 3-5 dominant emotions from a predefined list, presented as a horizontally scrollable set of illustrated boxes.
        - **Key Themes & Insights:** Presents up to 5 bullet points summarizing the main themes discussed.
        - **Actionable Steps:** Offers 1-3 specific, actionable steps for the user to take.
    - Once processing is complete, the page displays the insights generated by the LLM, divided into the four widgets.
5. **Performance Evaluation (Self-Reflection Score Page):**
    - A new page displays the user's self-reflection performance, evaluated by the Assessment LLM.
    - The generateAssessmentScores function is triggered after generateSmartAIStats completes.
    - The generateAssessmentScores function:
        - Retrieves the current session's transcript and timestamp.
        - Retrieves the timestamps of the user's past 3 "evaluated" sessions (if they exist).
        - Retrieves the transcripts of those past sessions using their timestamps.
        - Constructs a prompt for the Assessment LLM, including the current and past transcripts (and timestamps)
        - Sends the prompt to the Assessment LLM, instructing it to consider consistency and growth over time if past sessions are available.
        - Receives the scores and feedback (structured JSON).
        - Updates sessions/{sessionId}: stores scores/feedback, changes status to "evaluated".
    - Scores are displayed based on five predefined factors:
        - Clarity and Specificity
        - Emotional Insight
        - Actionability
        - Consistency and Growth
        - Values and Alignment
    - Each factor is presented with a numerical score and a brief explanation/feedback.
6. **Feedback Collection (Feedback Page):**
    - A feedback page appears with thumbs up/thumbs down options.
    - If the user selects thumbs down, they can provide further input in an optional text field.
    - Feedback data (rating and optional comment) is stored in a feedback subcollection within sessions/{sessionId}.
7. **Completion:**
    - User taps to finish the session and return to the home screen.
    - The home screen's dynamic content widget may now display personalized insights from the completed session.

**Specific Details of Interactive Reflection**

- Covers a range of questions and prompts tailored to user focus areas.
- Flexible flow, allowing free-form user input while staying guided by predefined objectives.
- Engages users in exploring emotions, thoughts, and behaviors.
- Adapts dynamically based on user responses to maintain a natural conversation.
- Incorporates a 5-second silence timer; if the user doesn't speak for 5 seconds, the AI prompts them with a relevant question or comment.

**Specific Details of Smart AI Insights**

The Smart AI Stats Page presents information in four distinct widgets:

- **Focus Area Reflection:**
    - Displays each of the user's two focus areas.
    - Includes a short paragraph for each, generated by the Smart AI Stats LLM, explaining how the session addressed that focus area.
- **Emotional Landscape:**
    - Presents 3-5 dominant emotions selected by the LLM from a predefined list (joy, sadness, anger, fear, anxiety, calm, frustration, excitement, contentment, disappointment, other).
    - Displayed as a horizontally scrollable set of boxes, each with an emotion name and a corresponding illustration (design to be handled by UI/UX).
- **Key Themes & Insights:**
    - A bullet-point list of up to 5 key themes or insights identified by the LLM from the session.
- **Actionable Steps:**
    - A numbered list of 1-3 specific, actionable steps generated by the LLM, tailored to the user's focus areas and session content.

The content for these widgets is generated by the **generateSmartAIStats** Cloud Function. The LLM is prompted to structure its output as a JSON object that corresponds to these four widgets.

**Specific Details of Performance Evaluation**

- The Assessment LLM is prompted to evaluate the user's self-reflection based on five core factors, taking into account up to three previous sessions if available.
- The LLM considers the timestamps of past sessions to understand the progression of the user's self-reflection journey.

**Core Quantifiable Factors and Questions**

- **Clarity and Specificity**
    - T/F: The user clearly described at least one specific situation or event from their day.
    - Scale 1-5: How detailed and concrete was the user's description of their experiences?
    - Scale 1-5: How clearly did the user identify the emotions or thoughts involved in the described situation?
    - T/F: The user avoided overly vague or generic statements, providing clear examples instead.
    - Scale 1-5: Overall, how understandable and coherent was the user's reflection?
- **Emotional Insight**
    - T/F: The user identified at least one distinct emotion they experienced.
    - Scale 1-5: How well did the user explain the reasons or triggers behind their emotions?
    - Scale 1-5: How effectively did the user connect their emotional state to their behaviors or reactions?
    - T/F: The user showed awareness of changes or patterns in their emotional states compared to previous sessions.
    - Scale 1-5: How much emotional depth and understanding did the user demonstrate today?
- **Actionability of Reflections**
    - T/F: The user proposed at least one concrete action or strategy to address the issues they discussed.
    - Scale 1-5: How clear and realistic were the user's suggested steps for improvement?
    - T/F: The user acknowledged any prior action steps from past sessions and reflected on their effectiveness (if applicable).
    - Scale 1-5: How confident or willing did the user appear in taking these new steps?
    - Scale 1-5: How directly do the proposed actions align with the user's stated goals?
- **Consistency and Growth Over Time**
    - T/F: The user referenced previous sessions, insights, or actions, showing continuity.
    - Scale 1-5: Compared to earlier reflections, how much improvement in clarity or understanding is evident?
    - T/F: The user displayed ongoing engagement and sincerity, rather than superficial participation.
    - Scale 1-5: How well did the user integrate past lessons or previous goals into today's reflection?
    - Scale 1-5: Does today's reflection show an evolving or more nuanced understanding compared to before?
- **Values and Alignment**
    - T/F: The user's reflection aligns with the specific focus areas they initially chose.
    - Scale 1-5: How clearly does the user connect today's insights or challenges to their long-term values or goals?
    - T/F: The user recognized any personal strengths or positive habits that support their chosen focus areas.
    - Scale 1-5: How consistently does the user's reflection reinforce previously stated values?
    - Scale 1-5: Did the user demonstrate gratitude, understanding, or any positive orientation that aligns with their desired growth areas?

**Scoring Methodology**

- Assessment LLM analyzes all available context: the current session transcript and up to three previous session transcripts, along with their timestamps.
- Answers factor questions based on comprehensive analysis, taking into account the progression and consistency (or lack thereof) over time.
- Generates scores out of 100 or 10 for each factor.
- Calculates overall self-reflection score.
- Provides directional feedback on progress, highlighting areas where the user has improved or needs further attention.

**Notes:**

- This document will be updated as the app evolves and new features are added.
- The specific prompts for the LLMs will be further refined during development and testing.
- User interface designs and specific wording on screens may be adjusted based on user feedback and testing.




Self-Reflection AI Assistant App - Technical Documentation

**Version: 0.1.1 (Draft - In Progress)**

**1. Introduction**

This document outlines the technical specifications for the Self-Reflection AI Assistant app. The app provides a user-friendly and accessible self-reflection experience through an AI-powered conversational interface. The core of the app is a real-time, voice-based conversation powered by the OpenAI Realtime API.

**2. Core Features**

- **Real-time Voice Conversation:** Users engage in a natural voice conversation with an AI assistant.
- **AI-Powered Responses:** The AI assistant (powered by the OpenAI Realtime API) guides the user through a self-reflection session using appropriate prompts and responses.
- **Dynamic Conversation Control:**
    - **Silence Handling:** The AI is programmed to recognize and respect periods of silence. Implementation: A 5-second timer starts after the user finishes speaking. If no further audio is detected, the AI offers a gentle prompt. If the user speaks, the timer resets.
    - **3-Minute Wrap-Up:** After 3 minutes, the client signals the AI to begin summarizing the conversation.
    - **5-Minute Hard Stop:** After 5 minutes, the client signals the AI to gracefully end the session.
- **Real-time Text Display (Assistant Only):** The assistant's responses are displayed as text in real-time during the conversation, using the response.text.delta events from the Realtime API.
- **Post-Session Transcription:** After the conversation, the session audio is transcribed using the OpenAI Whisper API. The transcript is stored in Firestore.
- **Smart AI Insights:** An analysis phase where the session transcript is processed (using a dedicated LLM) to extract insights, patterns, and areas for improvement. The results populate the Smart AI Stats Page.
- **Performance Evaluation:** An assessment phase where the user's reflection session is evaluated (using a dedicated LLM) based on predefined factors (Clarity, Emotional Insight, Actionability, Consistency, Values Alignment), taking into account up to three previous sessions for context.

**3. System Architecture**

The app utilizes a client-server architecture:

- **Client (iOS - SwiftUI):**
    - Handles user interface and interaction.
    - Manages WebRTC connection directly to the OpenAI Realtime API.
    - Records audio during the conversation.
    - Sends requests to Firebase Cloud Functions.
    - Displays real-time text from the AI assistant.
    - Handles push notifications.
    - Temporarily stores onboarding data until user account creation.
- **Firebase:**
    - **Authentication:** Manages user accounts and authentication (including anonymous).
    - **Cloud Firestore:** Stores user data, session data, onboarding data, and feedback data. (Refer to "Technical Documentation for Firestore" for details.)
    - **Cloud Functions:** Acts as a secure backend, handling tasks like obtaining ephemeral OpenAI API keys, audio transcription, insights generation, and performance evaluation. (Refer to "Technical Documentation for Cloud Functions" for details.)
    - **Secret Manager:** Securely stores the standard OpenAI API key.
    - **App Check:** Verifies that requests originate from legitimate app instances.
    - **Crashlytics:** Collects and analyzes app crash reports.
    - **Firebase Cloud Messaging (FCM):** Handles sending and receiving push notifications.
- **OpenAI APIs:**
    - **Realtime API:** Powers the real-time voice conversation (accessed directly by the client via WebRTC, authenticated with an ephemeral API key).
    - **Whisper API:** Used for post-session transcription.
    - **GPT-4o API (or similar):** Powers the Smart AI Stats LLM (for generating insights) and the Assessment LLM (for performance evaluation).

**4. Technology Stack**

- **Client:** SwiftUI (iOS Development), WebRTC, Firebase SDK
- **Backend:** Firebase (Authentication, Firestore, Cloud Functions, App Check, Secret Manager, Crashlytics, FCM), Node.js (for Cloud Functions)
- **AI:** OpenAI Realtime API, OpenAI Whisper API, OpenAI GPT-4o API (or similar)

**5. User Onboarding and Initial Setup Flow**

(Refer to "Self-Reflection AI Assistant App Concept" for a detailed user-facing description of the onboarding process.)

**5.1. App Launch and App Check Verification**

- **App Launch:** User opens the app.
- **App Check:** Automatic App Check token request and verification.
- **Crashlytics Initialization:** Crashlytics starts monitoring.
- **Check for Existing User:**
    - If an existing user (anonymous or authenticated) is found:
        - If anonymous, fetch onboarding/{userId} from Firestore and check the completed flag.
        - If authenticated, fetch users/{userId} and check the onboardingComplete flag.
        - If true (or completed for anonymous): Proceed to Home Screen (Section 5.17).
        - If false: Continue with onboarding (Section 5.2 Splash Screen).
    - If no user is found:
        - Perform anonymous sign-in.
        - Trigger the createOnboardingRecord Cloud Function to create an onboarding/{userId} document with initial values (step: 1, completed: false).

**5.2. Splash Screen**

- **Display:** Show a simple splash screen (1-2 seconds).
- **Background Tasks:** Allow Firebase initialization to complete.
- **Transition:** Proceed to the next step based on the logic in Step 5.1 (either Home Screen or Introduction with Illustrations).

**5.3. Introduction with Illustrations**

- **Display:** Present three sequential introductory content pieces (predefined in the app).
- **"Tap to Continue":** User proceeds by tapping "Tap to Continue".
- **Transition:** Navigate to Step 5.4: "Get Started for Free" or "Login".

**5.4. "Get Started for Free" or "Login"**

- **Display:** Present two options: "Get Started for Free" and "Log in".
    - **"Get Started for Free":** Go to Step 5.5: Welcome Page.
    - **"Log in":**
        - Call the updateOnboardingStep function with step: 14.
        - Proceed to Step 5.14: Account Setup.
- **Back Button Behavior:** If the user clicks the back button before successfully authenticating, they are taken back to the "Get Started for Free" or "Login" page. Call updateOnboardingStep function with step: 3.

**5.5. Welcome Page**

- **Display:** Show a welcome message (predefined in the app).
- **"Tap to Continue":** Go to Step 5.6: Focus Areas Selection.

**5.6. Focus Areas Selection**

- **Display:** Present the focus area options (predefined in the app).
- **Selection Handling:** Allow the user to select exactly two. Track selections in memory (e.g., in an OnboardingData instance).
- **Validation:** Enforce the selection of two focus areas.
- **Storage (Temporary):** Store selected focusAreaId values in the OnboardingData instance.
- **Transition:** Proceed to Step 5.7: Self-Promotion Page (1).

**5.7. Self-Promotion Page (1)**

- **Display:** Show the first self-promotion page (predefined in the app).
- **Transition:** Proceed to Step 5.8: Basic Information.

**5.8. Basic Information (Age, Gender)**

- **Display:** Collect user's age and gender.
- **Validation:** Perform basic client-side validation.
- **Storage (Temporary):** Store information in the OnboardingData instance.
- **Transition:** Proceed to Step 5.9: Baseline Questions (Part 1).

**5.9. Baseline Questions (Part 1)**

- **Display:** Present the first set of baseline questions (predefined in the app).
- **Storage (Temporary):** Store answers in the OnboardingData instance.
- **Transition:** Proceed to Step 5.10: Self-Promotion Page (2).

**5.10. Self-Promotion Page (2)**

- **Display:** Show the second self-promotion page (predefined in the app).
- **Transition:** Proceed to Step 5.11: Baseline Questions (Part 2).

**5.11. Baseline Questions (Part 2)**

- **Display:** Present the remaining baseline questions (predefined in the app).
- **Storage (Temporary):** Store answers in the OnboardingData instance.
- **Transition:** Proceed to Step 5.12: Reminder Setup.

**5.12. Reminder Setup**

- **Display:** Allow the user to select a daily reminder time.
- **Storage (Temporary):** Store the selected time in the OnboardingData instance.
- **Transition:**
    - Call the updateOnboardingStep function with step: 13.
    - Proceed to Step 5.13: Notification Permission.

**5.13. Notification Permission**

- **Display:** Request permission to send notifications.
- **FCM Token (if allowed):**
    - If granted, retrieve the FCM token.
    - Call the storeFCMToken Cloud Function to store the token in users/{userId}.
- **Transition:**
    - Call the updateOnboardingStep function with step: 14.
    - Proceed to Step 5.14: Account Setup.

**5.14. Account Setup**

- **Display:** Present login options: "Continue with Apple" and "Continue with Google".
- **Call the updateOnboardingStep function with step: 15.**
- **Firebase Authentication:** Handle authentication for each provider.
- **Back Button Behavior:** If the user clicks the back button before successfully authenticating, they are taken back to the "Get Started for Free" or "Login" page. Call updateOnboardingStep function with step: 3.
- **Link Anonymous Account:** Use linkWithCredential to link anonymous account data to the permanent account upon successful sign-in.
- **Check for Onboarding Completion:**
    - **Trigger:** Successful login or account creation.
    - **Check:** If the user is an existing user, fetch users/{userId} and check the onboardingComplete flag.
        - If true (onboarding complete): Proceed to Home Screen (5.17).
        - If false (onboarding incomplete): Proceed to Step 5.5 Welcome Page.
- **Store Onboarding Data (only if onboarding is not complete):**
    - **Trigger:** Successful login or account creation AND onboardingComplete is false.
    - **Action:** Call the storeOnboardingData Cloud Function to write the temporarily stored data to Firestore (to users/{userId} and users/{userId}/baselineAnswers). Set onboardingComplete to false in users/{userId}.
- **Transition:**
    - If onboarding was already complete: Proceed to Home Screen (5.17).
    - If onboarding was incomplete: Proceed to Step 5.5 Welcome Page.

**5.15. Paywall**

- **Display:** Show the paywall with subscription options.
- **Subscription Handling:** Handle purchases using StoreKit (or your chosen method).
- **Subscription Status:** Store the status in users/{userId} (e.g., "free", "subscribed", "trial").
- **"X" Button:** Allow the user to skip the paywall.
- **Transition:**
    - Call the updateOnboardingStep function with step: 16.
    - Proceed to Step 5.16: First Self-Reflection Loop.

**5.16. First Self-Reflection Loop**

- **Initiate:** Begin the first self-reflection session.
- **See Section 6 (Self-Reflection Loop)**
- **Completion:**
    - Update users/{userId}: Set onboardingComplete to true.
    - Check if this is the first time completing the loop:
        - If (and only if) onboardingComplete was false before the update:
            - Call the updateOnboardingStep function with step: 17 and completed: true.
- **Transition:** Proceed to Step 5.17: Home Screen.

**5.17. Home Screen**

- **Display:** Show the Home Screen.
- The user is now fully onboarded.

**6. Self-Reflection Loop**

**6.1. Initiation:**

- **User Action:** User taps "Let's Self-Reflect" on the Home Screen (or automatically initiated after the paywall during onboarding).
- **Client Actions:**
    - Creates a new document in sessions/{sessionId} with initial data:
        - userId
        - startTime
        - status: "initializing"
    - Calls the getEphemeralKey Cloud Function to obtain a short-lived OpenAI API key for the Realtime API.
    - Transitions to the Preparation Page.

**6.2. Preparation Page:**

- **Display:** "Take a deep breath and start when you are ready."
- **"Tap to Continue" button:** Enabled immediately.
- **User Action:** User taps "Tap to Continue".
- **Client Action:** Transitions to the Conversation Page.

**6.3. Conversation Page:**

- **Client Actions:**
    - Receives the ephemeral API key from the getEphemeralKey Cloud Function.
    - Establishes a WebRTC connection *directly* to the OpenAI Realtime API, using the ephemeral key for authentication.
    - Sends initial instructions, including the hardcoded system_prompt, directly to the Realtime API via the WebRTC data channel.
    - Updates the sessions/{sessionId} document, setting status to "in progress".
    - Starts a 3-minute timer and a 5-minute timer.
    - Starts recording the user's audio.

**6.4. Conversation:**

- **Audio Streaming:** User speaks; audio is streamed directly to the OpenAI Realtime API via WebRTC.
- **Realtime API Responses:** The Realtime API sends audio responses and response.text.delta events directly back to the client via WebRTC.
- **Real-time Text Display:** Client displays the AI's responses in real-time on the screen.
- **Silence Handling:** If the user stops speaking for 5 seconds, the AI interjects with a relevant prompt or question (based on logic within the Realtime API and the system_prompt).
- **User Input:** The client listens for client side events that signal to send to the Realtime API to prompt it to wrap up or end the session

**6.5. 3-Minute Wrap-Up:**

- **Trigger:** When the 3-minute timer elapses.
- **Client Action:** Sends a signal to the Realtime API (via the data channel) to prompt the AI to begin wrapping up the conversation.

**6.6. 5-Minute Hard Stop:**

- **Trigger:** When the 5-minute timer elapses.
- **Client Action:** Sends a signal to the Realtime API (via the data channel) to gracefully end the session.

**6.7. Conversation End:**

- **Realtime API Action:** Ends the session.
- **Client Actions:**
    - Stops recording audio.
    - Closes the WebRTC connection.
    - Disables the phone's back button functionality.
    - Updates endTime and status to "completed" in sessions/{sessionId}.
    - Initiates the transcription process by calling the transcribeAudio Cloud Function, sending the recorded audio file directly in the request body.
    - Transitions to the Smart AI Stats Page.
- **Cancellation:** If the user clicks the "x" button:
    - Client stops recording audio.
    - Closes the WebRTC connection.
    - Updates endTime and status to "cancelled" in sessions/{sessionId}.
    - Transitions to the Home Screen.

**6.8. Smart AI Stats Page (Transition):**

- **Display:** A loading indicator or message is displayed (e.g., "Analyzing your session...").
- **Background Task:** The transcribeAudio function, after successfully transcribing the audio and storing the transcript in Firestore, triggers the generateSmartAIStats Cloud Function.

**7. Post-Session Processing**

**7.1. Transcription:**

- **transcribeAudio Cloud Function:**
    - Receives the audio file and sessionId in the request body.
    - Retrieves the standard OpenAI API key from Secret Manager.
    - Calls the OpenAI Whisper API to transcribe the audio.
    - Updates sessions/{sessionId} in Firestore:
        - Sets the transcript field with the full text of the transcription.
        - Changes status to "transcribed".
    - Triggers the generateSmartAIStats Cloud Function, passing the sessionId.

**7.2. Smart AI Insights Generation:**

- **generateSmartAIStats Cloud Function (Continued):**
    - Constructs a prompt for the Smart AI Stats LLM, including:
        - System Role: Defines the LLM's role.
        - User's Focus Areas: The user's two selected focus areas.
        - Session Transcript: The full session transcript.
        - Instructions: Specific instructions for generating insights for each of the four widgets on the Smart AI Stats Page (Focus Area Reflection, Emotional Landscape, Key Themes & Insights, Actionable Steps).
        - Output Format: Specifies JSON output with a predefined schema that matches the four widgets.
        - Constraints: Limits on the number of emotions, key themes, and actionable steps.
    - Sends the prompt and transcript to the Smart AI Stats LLM (using the standard OpenAI API key from Secret Manager).
    - Receives the generated insights (structured JSON) from the LLM.
    - Updates sessions/{sessionId} in Firestore:
        - Stores the insights in the insights field.
        - Changes status to "insights_generated".
    - Triggers the generateAssessmentScores Cloud Function, passing the sessionId.

**7.3. Performance Evaluation:**

- **generateAssessmentScores Cloud Function:**
    - Receives the sessionId.
    - Retrieves the current session's data (userId, transcript, startTime) from sessions/{sessionId}.
    - Retrieves the timestamps of the user's past 3 "evaluated" sessions (if they exist) using a Firestore query that:
        - Filters by userId and status == "evaluated".
        - Orders by startTime descending.
        - Limits to 4 (to include current session).
        - Selects only the startTime field.
        - Excludes current session and then takes up to 3 most recent.
    - Retrieves the transcripts of those past sessions using their timestamps with individual queries.
    - Constructs a prompt for the Assessment LLM, including:
        - System Role: Defines the LLM's role as an evaluator of self-reflection sessions.
        - Current Session Transcript: The full transcript of the current session.
        - Current Session Timestamp: The timestamp of the current session.
        - Past Sessions (up to 3): The transcripts and timestamps of up to three previous sessions, dynamically included only if available. Past sessions are labeled "Past Session 1", "Past Session 2", etc.
        - Instructions: Instructs the LLM to evaluate the session based on the five factors (Clarity and Specificity, Emotional Insight, Actionability, Consistency and Growth, Values Alignment). If past sessions are provided, the LLM is instructed to consider the user's progress and consistency over time. If no past sessions are available, the evaluation should focus solely on the current session.
        - Output Format: Specifies JSON output with a predefined schema, including fields for each factor's score and feedback.
    - Sends the prompt to the Assessment LLM (using the standard OpenAI API key from Secret Manager).
    - Receives the scores and feedback (structured JSON) from the LLM.
    - Updates sessions/{sessionId} in Firestore:
        - Stores the scores and feedback in the evaluation field.
        - Changes status to "evaluated".

**8. Data Storage (Firestore)**

(Refer to the separate "Technical Documentation for Firestore" for more details)

- **users Collection:** Stores user-specific data.
- **users/{userId}/baselineAnswers (Subcollection):** Stores baseline answers.
- **sessions Collection:** Stores session data.
- **sessions/{sessionId}/feedback (Subcollection):** Stores feedback for each session.
- **onboarding Collection:** Tracks onboarding progress for anonymous users.

**9. Security Considerations**

- **OpenAI API Key Management:**
    - The standard API key is stored in Secret Manager and is only used on the server-side within Cloud Functions.
    - The getEphemeralKey Cloud Function provides short-lived, limited-scope keys for client-side access to the Realtime API.
- **Firebase App Check:** Enforced to ensure only legitimate app instances access Firebase.
- **Firebase Authentication:** Securely manages user authentication and authorization.
- **Firestore Security Rules:** Implemented to restrict data access based on user ownership (see "Technical Documentation for Firestore").
- **Data Validation:** Firebase Functions validate data received from the client before storing it.

**10. OpenAI API Usage**

- **Realtime API:**
    - **Connection:** WebRTC (established directly between the client and the OpenAI Realtime API).
    - **Authentication:** Ephemeral OpenAI API key (obtained via the getEphemeralKey Cloud Function).
    - **Client Events (sent to Realtime API):** response.create (for sending initial instructions and the system_prompt), custom events for wrap-up and session end signals, and potentially other custom events based on the evolving needs of the conversation flow.
    - **Server Events (received from Realtime API):** response.text.delta (for real-time text display), audio.output (for receiving audio data), potentially other events like error or status updates.
- **Whisper API:**
    - **Authentication:** Standard OpenAI API key (from Secret Manager in transcribeAudio function).
    - **Endpoint:** /transcriptions
    - **Input:** Audio file (sent directly in the request body from the client).
    - **Output:** JSON transcript, stored in Firestore.
- **GPT-4o API (or similar):**
    - **Authentication:** Standard OpenAI API key (from Secret Manager).
    - **Purpose:**
        - **Smart AI Stats LLM:** Generating insights from session transcripts.
        - **Assessment LLM:** Evaluating session transcripts and generating scores, considering past sessions for context.

**11. Future Development**

- **User Progress Tracking:** Data model for storing user progress over time, derived from the Assessment LLM's evaluations.
- **Advanced Analytics:** Explore more sophisticated analysis of user data to identify trends and patterns.
- **Personalized Recommendations:** Develop a system for providing personalized recommendations to users based on their progress, focus areas, and insights.

**12. Prompt Engineering**

(Refer to the "Self-Reflection AI Assistant App Concept" document for detailed prompt structures.)

- **Realtime API:** The hardcoded system_prompt defines the AI's behavior during the conversation. It's sent directly to the Realtime API via the WebRTC data channel at the start of the session.
- **Smart AI Stats LLM:** The prompt includes instructions for generating insights for each widget on the Smart AI Stats Page, tailored to the user's focus areas and the session transcript.
- **Assessment LLM:** The prompt includes instructions for evaluating the transcript based on five factors, taking into account up to three previous sessions (if available) to assess consistency and growth over time.

**13. Error Handling**

- **Realtime API Errors:** The client handles errors from the Realtime API, logs them, and displays appropriate error messages to the user. The client also implements appropriate reconnection strategies in case of temporary network issues.
- **Firebase Function Errors:** Cloud Functions handle errors, log them to Stackdriver, and potentially retry operations. They also update the session status in Firestore to indicate specific failure points (e.g., "transcription_failed", "insights_generation_failed", "evaluation_failed").
- **Whisper API Errors:** transcribeAudio handles errors from the Whisper API and implements a retry mechanism.
- **App Check Errors:** The app has a strategy for handling App Check verification failures.
- **Onboarding Errors:** Onboarding progress is reset if the app is closed before completion.
- **Smart AI Stats/Assessment LLM Errors:** Error messages are displayed on the respective pages, and retry options are provided.

**14. Scalability**

- **Firestore:** Designed to scale automatically.
- **Firebase Functions:** Scale automatically based on demand.
- **OpenAI APIs:** Be aware of rate limits and usage costs. Implement appropriate strategies for handling rate limiting (e.g., queuing, retries with exponential backoff).

**15. Testing**

- **Unit Tests:** For individual components (e.g., Cloud Functions, prompt construction logic).
- **Integration Tests:** For interaction between components (e.g., communication between client and Cloud Functions, interaction with Firestore and OpenAI APIs).
- **End-to-End Tests:** For the entire user flow, from starting a session to viewing results.
- **Prompt Engineering:** Thoroughly test and refine prompts to ensure they elicit the desired responses from the LLMs.

**16. Onboarding Data**

All onboarding data is hardcoded in the app except user inputs. Focus area options, including titles, descriptions, and illustrations, are predefined and stored within the app. The user's selections during onboarding are temporarily stored in memory on the client-side until the Account Setup step. Upon successful login or account creation, this data is then stored permanently in Firestore.

**17. Cloud Functions**

(Refer to the separate "Technical Documentation for Cloud Functions" for more details)

- **createOnboardingRecord:** Creates an onboarding record for new users (anonymous or authenticated). Triggered when a new user is created in Firebase Authentication.
- **updateOnboardingStep:** Updates the step and completed fields in the onboarding collection. Triggered at specific points during onboarding and when the back button is pressed during the login flow.
- **storeFCMToken:** Stores the user's FCM token in the users collection. Triggered when the user grants permission for push notifications.
- **storeOnboardingData:** Transfers temporarily stored onboarding data to the users collection and the users/{userId}/baselineAnswers subcollection. Triggered upon successful login or account creation.
- **getEphemeralKey:** Generates an ephemeral OpenAI API key with limited scope for use with the Realtime API. This key is provided to the client for direct interaction with the Realtime API during a session. Triggered by the client when initiating a new self-reflection session.
- **transcribeAudio:** Transcribes session audio using the OpenAI Whisper API. Stores the transcript in Firestore and triggers the generateSmartAIStats function. Triggered by the client after a session ends.
- **generateSmartAIStats:** Generates insights using the Smart AI Stats LLM. Processes the session transcript and user's focus areas to produce structured data for the Smart AI Stats Page. Triggered by the transcribeAudio function.
- **generateAssessmentScores:** Evaluates the session transcript using the Assessment LLM, considering up to three previous sessions for context, and generates scores based on predefined factors. Triggered by the generateSmartAIStats function.

**18. Firestore Database**

(Refer to the separate "Technical Documentation for Firestore" for more details)

- **users Collection:** Stores user-specific data, including:
    - userId (string): The user's unique ID.
    - email (string, if collected): The user's email address.
    - focusAreas (array of strings): The two focus areas chosen by the user.
    - age (number): The user's age.
    - gender (string): The user's gender.
    - reminderTime (string): The user's preferred reminder time.
    - fcmToken (string): The user's FCM token for push notifications.
    - subscriptionStatus (string): The user's subscription status ("free", "subscribed", "trial").
    - onboardingComplete (boolean): Indicates whether the user has completed the initial onboarding.
- **users/{userId}/baselineAnswers (Subcollection):** Stores the user's answers to baseline questions, with each document representing a single answer:
    - questionId (string): The ID of the baseline question.
    - answer (any): The user's answer (can be text, number, boolean, or array).
    - timestamp (timestamp): The time the answer was submitted.
- **sessions Collection:** Stores data for each self-reflection session, including:
    - userId (string): The ID of the user who conducted the session.
    - startTime (timestamp): The time the session started.
    - endTime (timestamp): The time the session ended.
    - status (string): The current status of the session ("initializing", "in progress", "completed", "transcribed", "insights_generated", "evaluated", "cancelled", "transcription_failed", "insights_generation_failed", "evaluation_failed").
    - transcript (string): The full transcript of the session.
    - insights (object): The insights generated by the Smart AI Stats LLM.
        - focus_area_1 (object):
            - name (string)
            - paragraph (string)
        - focus_area_2 (object):
            - name (string)
            - paragraph (string)
        - emotions (array): 3-5 dominant emotions.
        - key_themes (array): Up to 5 key themes.
        - actionable_steps (array): 1-3 actionable steps.
    - evaluation (object): The evaluation results from the Assessment LLM.
        - clarityScore (number)
        - emotionalInsightScore (number)
        - actionabilityScore (number)
        - consistencyAndGrowthScore (number)
        - valuesAlignmentScore (number)
        - clarityFeedback (string)
        - emotionalInsightFeedback (string)
        - actionabilityFeedback (string)
        - consistencyAndGrowthFeedback (string)
        - valuesAlignmentFeedback (string)
- **sessions/{sessionId}/feedback (Subcollection):** Stores feedback for each session:
    - rating (string): "thumbs_up" or "thumbs_down"
    - comment (string, optional): User's comment if rating is "thumbs_down"
    - timestamp (timestamp): Server timestamp.
- **onboarding Collection:** Tracks onboarding progress for anonymous users:
    - userId (string): The anonymous user's unique ID.
    - appVersion (string): The app version when the user started onboarding.
    - timestamp (timestamp): The time the onboarding record was created.
    - step (number): The current onboarding step the user has reached.
    - completed (boolean): Indicates whether the user has completed onboarding.

**19. Security**

- **OpenAI API Key:**
    - Standard key stored in Secret Manager and only used within Cloud Functions.
    - Ephemeral keys used for client-side Realtime API access, obtained via the getEphemeralKey Cloud Function.
- **App Check:** Enforced to verify legitimate app instances.
- **Authentication:** Firebase Authentication manages user authentication.
- **Firestore Security Rules:** Restrict data access based on user ownership.
- **Data Validation:** Cloud Functions validate data before storing it in Firestore.


Technical Documentation for Cloud Functions

**Version: 0.1.1 (Draft - In Progress)**

**1. Introduction**

This document details the Cloud Functions used in the Self-Reflection AI Assistant app. It outlines the purpose, trigger, inputs, outputs, error handling, and general flow for each function. These functions are written in Node.js and are designed to run in the Firebase Cloud Functions environment. They interact with other Firebase services like Firestore and Authentication, as well as with external APIs like the OpenAI API.

**2. Function List**

| **Function Name** | **Trigger** | **Description** |
| --- | --- | --- |
| createOnboardingRecord | Firebase Authentication (User Creation) | Creates a new onboarding record for a new user (anonymous or authenticated) in the onboarding collection. |
| updateOnboardingStep | HTTPS Callable | Updates the step field in the onboarding/{userId} document to track the user's onboarding progress. |
| storeFCMToken | HTTPS Callable | Stores or updates the user's Firebase Cloud Messaging (FCM) token in Firestore in the users collection. |
| storeOnboardingData | HTTPS Callable | Stores the user's onboarding data (collected during the temporary storage phase) to Firestore upon successful login or account creation. |
| getEphemeralKey | HTTPS Callable | Generates an ephemeral OpenAI API key with limited scope for use with the Realtime API. This key is provided to the client for direct interaction with the Realtime API during a session. |
| transcribeAudio | HTTPS Callable | Transcribes a session audio file using the OpenAI Whisper API and stores the transcript in Firestore. Triggers generateSmartAIStats. |
| generateSmartAIStats | HTTPS Callable (Triggered by transcribeAudio) | Processes the session transcript using the Smart AI Stats LLM to generate insights (structured JSON for the Smart AI Stats Page widgets). Stores the insights in Firestore and triggers generateAssessmentScores. |
| generateAssessmentScores | HTTPS Callable (Triggered by generateSmartAIStats) | Evaluates the session transcript using the Assessment LLM, considering up to three previous sessions, generates scores based on five predefined factors, and stores the scores and feedback in Firestore. |

Export to Sheets

**3. Function Details**

**3.1. createOnboardingRecord**

- **Purpose:** Creates a new onboarding record for a user when they first launch the app and are anonymously authenticated or when they create a new account. This record is used to track their progress through the onboarding flow.
- **Trigger:** providers/firebase.auth/eventTypes/user.create (Firebase Authentication - User Creation)
- **Inputs:**
    - user (UserRecord): The newly created user record (provided by the Authentication trigger).
- **Outputs:**
    - Creates a document in Firestore at onboarding/{userId} with the following fields:
        - userId (string): The user's unique ID.
        - appVersion (string): The current version of the app.
        - timestamp (timestamp): The server timestamp when the record was created.
        - step (number): Initialized to 1 (indicating the first step of onboarding).
        - completed (boolean): Initialized to false.
- **Error Handling:**
    - Logs errors to Stackdriver if Firestore document creation fails, including the error message and user ID.
- **Flow:**
    - The function is triggered when a new user is created in Firebase Authentication.
    - It extracts the userId from the provided user record.
    - It retrieves the appVersion from the app's environment variables.
    - It creates a new document in the onboarding collection with the user's ID as the document ID.
    - It populates the document with the initial onboarding data: userId, appVersion, timestamp, step (set to 1), and completed (set to false).

**3.2. updateOnboardingStep**

- **Purpose:** Updates the step field in the onboarding/{userId} document to track the user's progress through the onboarding flow.
- **Trigger:** HTTPS Callable (called from the client-side at various points during onboarding).
- **Inputs:**
    - step (number): The new step number to store.
    - completed (boolean, optional): Indicates whether onboarding is complete (only used when step is 17).
- **Outputs:**
    - Updates the onboarding/{userId} document, setting the step field to the provided value. If the step is 17, it also sets the completed field to true.
- **Error Handling:**
    - Logs errors to Stackdriver if Firestore document update fails, including the error message and user ID.
    - Returns an error to the client if the userId is not found in the request context or if the step is invalid.
- **Flow:**
    - The function is called from the client-side at specific points during the onboarding flow.
    - It receives the new step number as input.
    - It retrieves the user's ID (userId) from the authenticated request context.
    - It validates that the step number is within the acceptable range.
    - It updates the corresponding onboarding/{userId} document, setting the step field to the new value. If the new step is 17, it also sets the completed field to true.

**3.3. storeFCMToken**

- **Purpose:** Stores or updates the user's Firebase Cloud Messaging (FCM) token in Firestore. This token is used for sending push notifications.
- **Trigger:** HTTPS Callable (called from the client-side after the user grants notification permission).
- **Inputs:**
    - fcmToken (string): The user's FCM token.
- **Outputs:**
    - Updates the users/{userId} document in Firestore, setting the fcmToken field to the provided token.
- **Error Handling:**
    - Logs errors to Stackdriver if Firestore document update fails, including the error message and user ID.
    - Returns an error to the client if the userId is not found in the request context or if the fcmToken is invalid.
- **Flow:**
    - The function is called from the client-side after the user grants notification permission.
    - It receives the user's FCM token (fcmToken) as input.
    - It retrieves the user's ID (userId) from the authenticated request context.
    - It validates that the fcmToken is a valid format.
    - It updates the corresponding users/{userId} document in Firestore, setting the fcmToken field to the provided value. It uses a merge operation to ensure that only the fcmToken field is updated.

**3.4. storeOnboardingData**

- **Purpose:** Stores the user's onboarding data, collected during the temporary storage phase, to Firestore when the user successfully logs in or creates an account.
- **Trigger:** HTTPS Callable (called from the client-side after successful login/account creation).
- **Inputs:**
    - onboardingData (object): An object containing the onboarding data:
        - selectedFocusAreas (array of strings): The IDs of the two selected focus areas.
        - age (number): The user's age.
        - gender (string): The user's gender.
        - baselineAnswers (map of string to any): A map of question IDs to user answers.
        - reminderTime (string): The user's chosen reminder time.
- **Outputs:**
    - Creates or updates the users/{userId} document with the user's data.
    - Creates documents in the users/{userId}/baselineAnswers subcollection to store the baseline answers.
- **Error Handling:**
    - Logs errors to Stackdriver if Firestore document creation or update fails, including the error message and user ID.
    - Returns an error to the client if the userId is not found in the request context or if the onboardingData is invalid.
- **Flow:**
    - The function is called from the client-side after the user successfully logs in or creates an account.
    - It receives the onboardingData object as input.
    - It retrieves the user's ID (userId) from the authenticated request context.
    - It validates the onboardingData to ensure all required fields are present and in the correct format.
    - It performs a batch write operation to Firestore:
        - It creates or updates the users/{userId} document, populating it with the focusAreas, age, gender, reminderTime, and setting onboardingComplete to false.
        - For each baseline answer in baselineAnswers, it creates a new document in the users/{userId}/baselineAnswers subcollection, storing the questionId, answer, and a timestamp.

**3.5. getEphemeralKey**

- **Purpose:** Generates a short-lived, limited-scope OpenAI API key for use with the Realtime API. This enhances security by allowing the client to interact directly with the Realtime API for the duration of a single session without needing to store a long-lived key on the client-side.
- **Trigger:** HTTPS Callable (called from the client-side when initiating a new self-reflection session).
- **Inputs:** None
- **Outputs:**
    - key (string): The ephemeral OpenAI API key.
    - expires_at (number): The timestamp (in seconds since the Unix epoch) when the key expires.
- **Error Handling:**
    - Logs errors to Stackdriver if Secret Manager access fails or if ephemeral key generation fails.
    - Returns an error to the client if the key cannot be retrieved or generated, including an error code and a user-friendly message.
- **Flow:**
    - The function is called from the client-side when initiating a new self-reflection session.
    - It retrieves the standard OpenAI API key from Google Cloud Secret Manager.
    - It calls the OpenAI API's /ephemeral_keys endpoint, passing the standard API key in the Authorization header.
    - It sets the time_valid_ms parameter to define the key's validity period (e.g., 300000 milliseconds for 5 minutes, to match the maximum session length).
    - It sets the scope parameter to restrict the key's usage to only real-time audio processing.
    - It receives the ephemeral key and expiration timestamp from the OpenAI API.
    - It returns the generated ephemeral key and its expiration timestamp to the client.

**3.6. transcribeAudio**

- **Purpose:** Transcribes a session's audio recording using the OpenAI Whisper API and stores the resulting transcript in Firestore.
- **Trigger:** HTTPS Callable (called directly from the client after a session ends).
- **Inputs:**
    - sessionId (string): The ID of the session.
    - audioFile (binary): The audio file data, sent in the request body.
- **Outputs:**
    - Updates the sessions/{sessionId} document in Firestore:
        - Sets the transcript field with the full text of the transcription.
        - Changes the status field to "transcribed".
    - Triggers the generateSmartAIStats function with the sessionId.
- **Error Handling:**
    - Logs errors to Stackdriver (e.g., Whisper API errors, Firestore errors), including the error message and sessionId.
    - Updates the sessions/{sessionId} document with a "transcription_failed" status if an error occurs.
    - Implements a retry mechanism with exponential backoff for transient errors (e.g., network issues).
    - Returns an error to the client if transcription fails after retries, including an error code and a user-friendly message.
    - Sets a maximum request size limit slightly above 25 MB to prevent exceeding the Whisper API's file size limit.
- **Flow:**
    - The function is called from the client-side after a session ends.
    - It receives the sessionId and the audioFile in the request body.
    - It validates the audioFile size and format.
    - It retrieves the standard OpenAI API key from Google Cloud Secret Manager.
    - It sends the audio file directly to the OpenAI Whisper API's /transcriptions endpoint using the standard API key for authentication. It specifies model: "whisper-1" and response_format: "json".
    - It receives the transcription (JSON) from the Whisper API.
    - It updates the corresponding sessions/{sessionId} document in Firestore, setting the transcript field to the full text of the transcription and updating the status field to "transcribed".
    - It calls the generateSmartAIStats function, passing the sessionId as an argument.

**3.7. generateSmartAIStats**

- **Purpose:** Processes the session transcript using the Smart AI Stats LLM to generate insights for the Smart AI Stats Page widgets.
- **Trigger:** HTTPS Callable (called by the transcribeAudio function after successful transcription).
- **Inputs:**
    1. sessionId (string): The ID of the session being processed.
- **Outputs:**
    1. Updates the sessions/{sessionId} document in Firestore:
        - Stores the generated insights in the insights field as a structured JSON object.
        - Changes the status field to "insights_generated".
    2. Triggers the generateAssessmentScores function with the sessionId.
- **Error Handling:**
    1. Logs errors to Stackdriver (e.g., LLM API errors, Firestore errors), including the error message and sessionId.
    2. Updates the sessions/{sessionId} document with an "insights_generation_failed" status if an error occurs.
    3. Implements a retry mechanism for transient errors.
    4. Returns an error to the calling function if insights generation fails after retries.
- **Flow:**
    1. The function is triggered by the transcribeAudio function after the transcript is stored.
    2. It receives the sessionId as input.
    3. It retrieves the transcript from the sessions/{sessionId} document in Firestore using a targeted query.
    4. It retrieves the user's focusAreas from the users/{userId} document in Firestore (by fetching the userId from the session document) using another targeted query.
    5. It constructs a prompt for the Smart AI Stats LLM. The prompt includes:
        - **System Role:** Defines the LLM's role as a helpful assistant analyzing self-reflection sessions.
        - **User's Focus Areas:** The user's two selected focus areas.
        - **Session Transcript:** The full transcript from the Whisper API.
        - **Instructions:** Specific instructions for generating insights for each of the four widgets on the Smart AI Stats Page:
            - **Focus Area Reflection:** "For each focus area provided, write a short paragraph (2-3 sentences) explaining how this session helped address that area. Be specific and reference details from the session transcript."
            - **Emotional Landscape:** "Based on the session transcript, select the 3-5 most dominant emotions from this list: [predefined list of emotions]. Provide the emotions as an array."
            - **Key Themes & Insights:** "Identify and list up to 5 key themes or insights discussed in the session. Each theme should be a concise bullet point."
            - **Actionable Steps:** "Based on the session and the user's focus areas, suggest 1-3 specific, actionable steps the user can take to further their self-reflection or work towards their goals. Each step should be a concise, numbered point."
        - **Output Format:** Specifies that the output should be in JSON format, structured according to a predefined schema that matches the four widgets. Example:
        "Output Format:\\n" + "{\\n" + " \\"focus_area_1\\": {\\"name\\": \\"\\", \\"paragraph\\": \\"\\"},\\n" + " \\"focus_area_2\\": {\\"name\\": \\"\\", \\"paragraph\\": \\"\\"},\\n" + " \\"emotions\\": [],\\n" + " \\"key_themes\\": [],\\n" + " \\"actionable_steps\\": []\\n" + "}"
        - **Constraints:** Includes constraints like "Do not use any emotions outside of the provided list," "Limit the Key Themes & Insights to a maximum of 5 bullet points," etc.
    6. It sends the prompt and the transcript to the Smart AI Stats LLM (using the OpenAI API and the standard key from Secret Manager).
    7. It receives the generated insights (structured JSON) from the LLM.
    8. It updates the sessions/{sessionId} document, storing the entire JSON object in the insights field and updating the status to "insights_generated".
    9. It calls the generateAssessmentScores function, passing the sessionId as an argument.

**3.8. generateAssessmentScores (Continued)**

- **Purpose:** Evaluates the user's self-reflection session transcript using the Assessment LLM, generates scores based on five predefined factors, and provides feedback, taking into account up to three previous sessions for context.
- **Trigger:** HTTPS Callable (Triggered by generateSmartAIStats)
- **Inputs:**
    1. sessionId (string): The ID of the session being evaluated.
- **Outputs:**
    1. Updates the sessions/{sessionId} document in Firestore:
        - Stores the scores and feedback in the evaluation field (structured JSON).
        - Changes the status field to "evaluated".
- **Error Handling:**
    1. Logs errors to Stackdriver (e.g., LLM API errors, Firestore errors), including the error message and sessionId.
    2. Updates the sessions/{sessionId} document with an "evaluation_failed" status if an error occurs.
    3. Implements a retry mechanism for transient errors.
    4. Returns an error to the calling function if evaluation fails after retries.
- **Flow:**
    1. The function is triggered by generateSmartAIStats after insights are generated.
    2. It receives the sessionId as input.
    3. **Retrieve Current Session Data:**
        - It retrieves the current session's data (userId, transcript, startTime) from sessions/{sessionId} using a targeted query.
    4. **Retrieve Past Session Timestamps:**
        - It queries Firestore to get the startTime timestamps of the user's past sessions from the sessions collection.
        - The query filters by userId and status == "evaluated", orders by startTime descending, limits to the 4 most recent timestamps, selects only the startTime field.
        - The function then excludes the current session timestamp and takes up to 3 of the remaining timestamps
    5. **Retrieve Past Session Transcripts:**
        - It uses those timestamps to retrieve the corresponding session documents from sessions collection.
        - For each retrieved session it extracts the transcript and startTime.
    6. **Construct the Prompt:**
        - It constructs a prompt for the Assessment LLM. The prompt includes:
            - **System Role:** Defines the LLM's role as a helpful assistant evaluating self-reflection sessions based on predefined factors, considering progress and consistency over time.
            - **Current Session Transcript:** The full transcript of the current session.
            - **Current Session Timestamp:** The timestamp of the current session (formatted in a human-readable way).
            - **Past Sessions (up to 3):** The transcripts and timestamps of up to three previous sessions, dynamically included only if available. Past sessions are labeled "Past Session 1", "Past Session 2", etc.
            - **Instructions:** Specific instructions for evaluating the session based on the five factors:
                - **Clarity and Specificity:** Evaluate the clarity and specificity of the user's reflections.
                - **Emotional Insight:** Assess the user's emotional awareness and understanding.
                - **Actionability:** Evaluate the extent to which the user identifies actionable steps.
                - **Consistency and Growth:** Assess the user's consistency and growth over time, referencing the past sessions if provided.
                - **Values Alignment:** Evaluate how well the user's reflections align with their stated values and goals.
                - For each factor, provide a score (e.g., out of 100) and a brief feedback string (1-2 sentences).
            - **Output Format:** Specifies that the output should be in JSON format, structured according to a predefined schema. Example:
            "Output Format:\\n" + "{\\n" + " \\"clarityScore\\": 0,\\n" + " \\"clarityFeedback\\": \\"\\",\\n" + " \\"emotionalInsightScore\\": 0,\\n" + " \\"emotionalInsightFeedback\\": \\"\\",\\n" + " \\"actionabilityScore\\": 0,\\n" + " \\"actionabilityFeedback\\": \\"\\",\\n" + " \\"consistencyAndGrowthScore\\": 0,\\n" + " \\"consistencyAndGrowthFeedback\\": \\"\\",\\n" + " \\"valuesAlignmentScore\\": 0,\\n" + " \\"valuesAlignmentFeedback\\": \\"\\"\\n" + "}"
    7. **Send Prompt to Assessment LLM:**
        - It sends the prompt to the Assessment LLM (using the OpenAI API and the standard key from Secret Manager).
    8. **Receive and Process Response:**
        - It receives the generated scores and feedback (structured JSON) from the LLM.
        - It parses the JSON response.
        - It validates the response against the expected schema.
    9. **Store Evaluation in Firestore:**
        - It updates the sessions/{sessionId} document, storing the entire JSON object in the evaluation field and updating the status to "evaluated".

**4. Error Handling**

Each Cloud Function includes comprehensive error handling to catch, log, and manage errors gracefully.

- **Try-Catch Blocks:** Used to handle potential exceptions during API calls, Firestore operations, and other processes.
- **Error Logging:** console.error() or a dedicated logging service (like Stackdriver) is used to record error details for debugging. When an error occurs, the following information is logged:
    - The function name.
    - The sessionId (if applicable).
    - A timestamp.
    - The error message.
    - Relevant contextual information (e.g., the specific API call that failed, input parameters).
- **Status Updates in Firestore:**
    - If an error occurs during transcription, the transcribeAudio function updates the session status in Firestore to "transcription_failed".
    - If an error occurs during insights generation, the generateSmartAIStats function updates the session status to "insights_generation_failed".
    - If an error occurs during evaluation, the generateAssessmentScores function updates the session status to "evaluation_failed".
- **Retries:** Retry mechanisms with exponential backoff are implemented for transient errors, such as temporary network issues or temporary API outages.
    - The transcribeAudio function retries the Whisper API call a limited number of times if it fails.
    - The generateSmartAIStats and generateAssessmentScores functions might retry calling the respective LLMs if they encounter transient errors.
- **Client-Side Handling:** The client-side app monitors the session status in Firestore. If a failure status is detected, the app displays appropriate error messages or retry options to the user.
- **Dead-letter Queue (Future Improvement):** For more complex error handling, consider implementing a dead-letter queue to store failed operations that require manual intervention or further investigation.

**5. Security**

- **OpenAI API Key:** The standard OpenAI API key is stored securely in Google Cloud Secret Manager and is only accessed by authorized Cloud Functions (transcribeAudio, generateSmartAIStats, and generateAssessmentScores). Ephemeral keys are used for client-side Realtime API access.
- **Firebase App Check:** Enforced to verify that requests to Cloud Functions originate from legitimate app instances. This helps prevent abuse and unauthorized access.
- **Firebase Authentication:** Used to manage user authentication and authorization. Security rules are implemented to ensure that users can only access their own data.
- **Firestore Security Rules:** Define strict rules to control data access based on user ownership. For example:
    - Users can only read and write to their own documents in the users collection.
    - Users can only read session documents (sessions/{sessionId}) where the userId field matches their own user ID.
    - Anonymous users can only create and update their own onboarding documents (onboarding/{userId}).
- **Data Validation:** Cloud Functions validate data received from the client before storing it in Firestore. This includes:
    - Type checking (e.g., ensuring that step is a number in updateOnboardingStep).
    - Data sanitization (e.g., escaping special characters to prevent injection attacks).
    - Input validation for the transcribeAudio function to check the audio file size and format.

**6. Future Improvements**

- **Pub/Sub for Asynchronous Processing:** Consider using a Pub/Sub queue to decouple the transcribeAudio, generateSmartAIStats, and generateAssessmentScores functions. This would improve scalability and resilience by allowing these functions to operate independently and asynchronously. Messages would be published to specific topics after each stage (e.g., "transcription_completed"), and the subsequent functions would be triggered by subscribing to those topics.
- **Advanced Error Handling:** Implement more sophisticated error handling, such as:
    - Sending notifications to the user (e.g., via email or push notifications) for specific error types (e.g., "Your session audio could not be transcribed").
    - Providing more detailed error messages on the client-side based on the specific error that occurred, along with potential solutions or workarounds.
- **Performance Optimization:** Continuously monitor and optimize function execution time to minimize latency for the user. This could involve:
    - Optimizing code for efficiency (e.g., using asynchronous operations where possible, minimizing Firestore reads and writes).
    - Using caching where appropriate (e.g., caching the user's focus areas in generateSmartAIStats to avoid repeated lookups).
    - Choosing the appropriate instance size (memory and CPU) for each Cloud Function based on its resource requirements.
- **Monitoring and Alerting:** Set up monitoring and alerting for Cloud Function errors, latency, and resource usage to proactively identify and address performance bottlenecks or issues. Tools like Stackdriver Monitoring and Logging can be used for this purpose.


Technical Documentation for Firestore

**Version: 0.1.2 (Draft - In Progress)**

**1. Introduction**

This document outlines the Firestore database structure used in the Self-Reflection AI Assistant app. It describes the collections, documents, fields, and data types used to store user data, session data, onboarding information, and user feedback. It also includes Firestore security rules to protect data integrity and confidentiality.

**2. Database Structure Overview**

The Firestore database is organized into the following collections:

- **users:** Stores user-specific data.
- **sessions:** Stores data related to each self-reflection session.
- **onboarding:** Tracks the onboarding progress of anonymous users.

**3. Collection Details**

**3.1. users Collection**

- **Purpose:** Stores data for each user in the app.
- **Document ID:** {userId} (The user's unique ID from Firebase Authentication)
- **Fields:**

| **Field** | **Data Type** | **Description** |
| --- | --- | --- |
| userId | string | The user's unique ID (same as the document ID). |
| email | string | The user's email address (if collected during account creation). |
| focusAreas | array | An array of strings representing the two focus areas selected by the user during onboarding. |
| age | number | The user's age. |
| gender | string | The user's gender. |
| reminderTime | string | The user's preferred daily reminder time (e.g., "08:00"). |
| fcmToken | string | The user's Firebase Cloud Messaging token for push notifications (if available). |
| subscriptionStatus | string | The user's subscription status: "free", "subscribed", or "trial". |
| onboardingComplete | boolean | Indicates whether the user has completed the initial self-reflection loop (and thus, onboarding). |

Export to Sheets

- **Subcollections:**
    - **baselineAnswers:** Stores the user's answers to the baseline questions.
        - **Document ID:** Auto-generated unique ID
        - **Fields:**

| **▪    Field** | **▪    Data Type** | **▪    Description** |
| --- | --- | --- |
| ▪    questionId | ▪    string | ▪    Identifier of the baseline question. |
| ▪    answer | ▪    any | ▪    The user's answer (can be text, number, boolean, or array). |
| ▪    timestamp | ▪    timestamp | ▪    Timestamp when the answer was submitted. |

**3.2. sessions Collection**

- **Purpose:** Stores data for each self-reflection session conducted by users.
- **Document ID:** {sessionId} (A unique ID generated for each session)
- **Fields:**

| **Field** | **Data Type** | **Description** |
| --- | --- | --- |
| userId | string | The ID of the user who conducted the session. |
| startTime | timestamp | Timestamp when the session started. |
| endTime | timestamp | Timestamp when the session ended. |
| status | string | The status of the session: "initializing", "in progress", "completed", "transcribed", "insights_generated", "evaluated", "cancelled", "transcription_failed", "insights_generation_failed", "evaluation_failed". |
| transcript | string | The full text transcript of the session, generated by the OpenAI Whisper API. |
| insights | object | Stores insights extracted from the transcript by the Smart AI Insights LLM. |
| evaluation | object | Stores the results of the Performance Evaluation performed by the Assessment LLM. |

Export to Sheets

- **insights field (object):**

| **Field** | **Data Type** | **Description** |
| --- | --- | --- |
| focus_area_1 | object | Container for first focus area data. |
| - name | string | Name of the first focus area. |
| - paragraph | string | LLM-generated paragraph explaining how the session addressed this focus area. |
| focus_area_2 | object | Container for second focus area data. |
| - name | string | Name of the second focus area. |
| - paragraph | string | LLM-generated paragraph explaining how the session addressed this focus area. |
| emotions | array | 3-5 dominant emotions selected from a predefined list. |
| key_themes | array | Up to 5 bullet points summarizing the main themes discussed. |
| actionable_steps | array | 1-3 specific, actionable steps for the user. |

Export to Sheets

- **evaluation field (object):**

| **Field** | **Data Type** | **Description** |
| --- | --- | --- |
| clarityScore | number | Score for Clarity and Specificity (out of 10 or 100). |
| emotionalInsightScore | number | Score for Emotional Insight (out of 10 or 100). |
| actionabilityScore | number | Score for Actionability (out of 10 or 100). |
| consistencyAndGrowthScore | number | Score for Consistency and Growth (out of 10 or 100). |
| valuesAlignmentScore | number | Score for Values Alignment (out of 10 or 100). |
| clarityFeedback | string | Feedback on Clarity and Specificity. |
| emotionalInsightFeedback | string | Feedback on Emotional Insight. |
| actionabilityFeedback | string | Feedback on Actionability. |
| consistencyAndGrowthFeedback | string | Feedback on Consistency and Growth. |
| valuesAlignmentFeedback | string | Feedback on Values Alignment. |

Export to Sheets

- **Subcollections:**
    - **feedback:** Stores feedback for each session.
        - **Document ID:** Auto-generated unique ID
        - **Fields:**

| **▪    Field** | **▪    Data Type** | **▪    Description** |
| --- | --- | --- |
| ▪    rating | ▪    string | ▪    "thumbs_up" or "thumbs_down" |
| ▪    comment | ▪    string | ▪    User's comment if rating is "thumbs_down" (optional) |
| ▪    timestamp | ▪    timestamp | ▪    Server timestamp |

**3.3. onboarding Collection**

- **Purpose:** Tracks the onboarding progress of anonymous users.
- **Document ID:** {userId} (The anonymous user's ID)
- **Fields:**

| **Field** | **Data Type** | **Description** |
| --- | --- | --- |
| userId | string | The anonymous user's unique ID. |
| appVersion | string | The version of the app when the user started onboarding. |
| timestamp | timestamp | Timestamp when the user started onboarding. |
| step | number | The current step in the onboarding process the user has reached (1-17). |
| completed | boolean | Indicates whether the user has completed the entire onboarding process. |

Export to Sheets

**4. Firestore Security Rules**

JavaScript

`rules_version = '2'; service cloud.firestore { match /databases/{database}/documents {

**// Users can read, update their own data, and create their user document**

**match /users/{userId} {**

**allow read, update: if request.auth != null && request.auth.uid == userId;**

**allow create: if request.auth != null;**

**}**

**// Users can read and write to their own baselineAnswers subcollection**

**match /users/{userId}/{subcollection}/{document=**} {**

**allow read, write: if request.auth != null && request.auth.uid == userId;**

**}**

**// Users can read their own session data**

**match /sessions/{sessionId} {**

**allow read: if request.auth != null && resource.data.userId == request.auth.uid;**

**allow write: if request.auth != null; // Allow Cloud Functions to create and update sessions**

**}**

**// Users can read and write to their own feedback subcollection within a session**

**match /sessions/{sessionId}/feedback/{feedbackId} {**

**allow read, write: if request.auth != null && get(/databases/$(database)/documents/sessions/$(sessionId)).data.userId == request.auth.uid;**

**}**

**// Users can read their own onboarding document**

**// Anonymous users can create and update their own onboarding document**

**match /onboarding/{userId} {**

**allow read: if request.auth != null && request.auth.uid == userId;**

**allow write: if request.auth != null;**

**}**

} }`

**Security Rules Explanation:**

- **users Collection:**
    - Users can read and update their own documents.
    - Users can create their document upon login/signup.
- **users/{userId}/baselineAnswers Subcollection:**
    - Users can read and write to their own baselineAnswers documents.
- **sessions Collection:**
    - Users can read session documents that belong to them (where userId matches their own ID).
    - Cloud Functions can write to any session document (for transcription, insights, evaluation, and feedback storage).
- **sessions/{sessionId}/feedback Subcollection:**
    - Users can read and write to their own feedback documents within a session
- **onboarding Collection:**
    - Users can read their own onboarding document.
    - Anonymous users can write to their own document (to track progress).

**5. Common Queries**

**5.1. User-Specific Queries**

JavaScript

`// Get user data db.collection('users').doc(userId).get();

// Get user's baseline answers db.collection('users').doc(userId).collection('baselineAnswers').get();

// Get a specific baseline answer db.collection('users').doc(userId).collection('baselineAnswers').doc(answerId).get();

// Get user's focus areas db.collection('users').doc(userId).get().then(doc => doc.data().focusAreas);`

**5.2. Session-Specific Queries**

JavaScript

`// Get all sessions for a user db.collection('sessions').where('userId', '==', userId).get();

// Get a specific session db.collection('sessions').doc(sessionId).get();

// Get sessions within a time range db.collection('sessions') .where('userId', '==', userId) .where('startTime', '>=', startTimestamp) .where('startTime', '<=', endTimestamp) .get();

// Get the 3 most recent evaluated sessions for a user, excluding the current session async function getPastSessions(userId, currentSessionId) { const pastSessionsQuery = await db.collection('sessions') .where('userId', '==', userId) .where('status', '==', 'evaluated') .orderBy('startTime', 'desc') .limit(4) .select('startTime') .get();

const pastSessionTimestamps = []; pastSessionsQuery.forEach(doc => { if ([doc.id](http://doc.id/) !== currentSessionId) { pastSessionTimestamps.push(doc.data().startTime); } });

const relevantPastSessions = []; for (const timestamp of pastSessionTimestamps) { const sessionQuery = await db.collection('sessions') .where('userId', '==', userId) .where('status', '==', 'evaluated') .where('startTime', '==', timestamp) .limit(1) .get();

**if (!sessionQuery.empty) {**

**const sessionDoc = sessionQuery.docs[0];**

**relevantPastSessions.push({**

**transcript: sessionDoc.data().transcript,**

**timestamp: sessionDoc.data().startTime**

**});**

**}**

} return relevantPastSessions; }`

**5.3. Onboarding Queries**

JavaScript

**// Get User's Onboarding Record db.collection('onboarding').doc(userId).get();**

**6. Notes**

- This document will be updated as the app evolves and new data storage requirements emerge.
- Consider adding indexes to Firestore to optimize query performance, especially for the sessions collection where you'll likely be querying by userId and startTime.
- The current security rules allow Cloud Functions to write to any session document. This is necessary for the post-session processing, but ensure that only authorized Cloud Functions have this permission. Regularly review these rules.
- Regular backups of the Firestore database should be configured to prevent data loss.
- Consider implementing data migration strategies for future schema changes. You might need to update existing documents when you add new fields or change data types.

**7. Future Considerations**

- **User Progress Tracking:** You might need a separate collection or sub-collection to store long-term user progress data derived from the assessment scores. This would allow for more sophisticated analysis and reporting.
- **Data Retention Policy:** Define a data retention policy. How long will you store session transcripts and other user data? Consider anonymizing or deleting data after a certain period to comply with privacy regulations.
- **Advanced Analytics:** As your app grows, you might want to use BigQuery or other data warehousing solutions for more in-depth analysis of user data and app usage patterns.

