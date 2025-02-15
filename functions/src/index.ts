import {initializeApp} from "firebase-admin/app";
initializeApp();
export {handleUserRecord, updateUserSignIn} from "./createOnboardingRecord";
export {storeOnboardingData} from "./storeOnboardingData";
export {getEphemeralKey} from "./getEphemeralKey";
export {transcribeAudio} from "./getEphemeralKey";
export {generateSmartAIStats} from "./generateSmartAIStats";
export {updateCoreMemories} from "./updateCoreMemories";
export {saveFeedback} from "./saveFeedback";
