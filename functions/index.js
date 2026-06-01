const functions = require("firebase-functions");
const axios = require("axios");

// This function acts as a secure proxy to AWS Bedrock.
// It ensures that the BEDROCK_API_KEY is NEVER sent to the client browser.
// It also verifies that the request comes from an authenticated Firebase user.

exports.callBedrock = functions.https.onCall(async (data, context) => {
  // 1. Verify Authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  // 2. Extract Data
  const { systemPrompt, userMessage, modelId = "us.anthropic.claude-sonnet-4-6" } = data;
  if (!userMessage) {
    throw new functions.https.HttpsError("invalid-argument", "userMessage is required.");
  }

  // 3. Load Secure Environment Variable
  // Note: Set this in your Firebase project using:
  // firebase functions:config:set aws.bedrock_key="YOUR_ACTUAL_KEY"
  const apiKey = functions.config().aws.bedrock_key;
  if (!apiKey) {
    throw new functions.https.HttpsError("internal", "Server configuration error.");
  }

  const region = "us-east-1";
  const apiUrl = `https://bedrock-runtime.${region}.amazonaws.com/model/${encodeURIComponent(modelId)}/converse`;

  const payload = {
    system: systemPrompt ? [{ text: systemPrompt }] : [],
    messages: [
      {
        role: "user",
        content: [{ text: userMessage }]
      }
    ]
  };

  try {
    const response = await axios.post(apiUrl, payload, {
      headers: {
        "Authorization": `Bearer ${apiKey}`,
        "Content-Type": "application/json"
      }
    });

    if (response.status === 200) {
      return {
        text: response.data.output.message.content[0].text
      };
    } else {
      throw new functions.https.HttpsError("internal", `AWS Error: ${response.status}`);
    }
  } catch (error) {
    console.error("Bedrock Proxy Error:", error.message);
    throw new functions.https.HttpsError("internal", "Failed to communicate with AI provider.");
  }
});
