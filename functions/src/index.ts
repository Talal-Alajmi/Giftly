import {onRequest} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import * as functions from "firebase-functions";

// Initialize Firebase Admin
admin.initializeApp();

// Define your Verify Token
const VERIFY_TOKEN = "123654665489555545";

// Webhook verification endpoint and message handler
export const handlleWhatsAppReply = onRequest((request, response) => {
  try {
    const mode = request.query["hub.mode"];
    const token = request.query["hub.verify_token"];
    const challenge = request.query["hub.challenge"];

    // Verification request
    if (mode && token && challenge) {
      if (mode === "subscribe" && token === VERIFY_TOKEN) {
        logger.info("Verification successful");
        response.status(200).send(challenge);
        return;
      } else {
        logger.warn("Verification failed: Invalid token or mode");
        response.sendStatus(403); // Forbidden
        return;
      }
    }

    // Message handling request
    const data = request.body;
    logger.info("Received data:", JSON.stringify(data, null, 2));

    // Check if the request contains valid data
    if (
      data.object === "whatsapp_business_account" &&
      data.entry &&
      Array.isArray(data.entry) &&
      data.entry.length > 0 &&
      data.entry[0].changes &&
      Array.isArray(data.entry[0].changes) &&
      data.entry[0].changes.length > 0 &&
      data.entry[0].changes[0].field === "messages" &&
      data.entry[0].changes[0].value &&
      data.entry[0].changes[0].value.messages &&
      data.entry[0].changes[0].value.messages.length > 0
    ) {
      const message = data.entry[0].changes[0].value.messages[0];

      // Check if the message is of type "interactive" and "button_reply"
      if (message.type === "button") {
        let buttonTitle = message.button.text;

        // Convert button title to corresponding status
        if (buttonTitle === "رفض") {
          buttonTitle = "Declined";
        } else if (buttonTitle === "قبول") {
          buttonTitle = "attending";
        } else {
          // If button title is not "رفض" or "قبول", skip saving
          logger.warn("Button neitherskipping save.");
          response.sendStatus(200); // Success
          return;
        }

        // Extract phone number
        const phoneNumber = message.from;
        const eventId = message.button.payload.substring(1);

        // Save interactive message data to Firestore
        admin
          .firestore()
          .collection("events")
          .doc(eventId)
          .collection("attendees")
          .doc(phoneNumber)
          .update({status: buttonTitle})
          .then(() => {
            logger.info("Interactive message saved to Firestore");
            response.sendStatus(200); // Success
          })
          .catch((error) => {
            logger.error("Error saving Firestore:", error);
            response.sendStatus(500); // Internal Server Error
          });
      } else {
        // Handle non-interactive messages or other types if needed
        logger.warn("Received a non-interactive message");
        response.sendStatus(200); // Success
      }
    } else {
      // If no valid data, respond with success status
      logger.warn("No valid data received");
      response.sendStatus(200); // Success
    }
  } catch (error) {
    logger.error("Message handling failed:", error);
    response.sendStatus(500); // Internal Server Error
  }
});

// Cloud Function to send notifications on feed item update
export const sendNoificationOnFeedItemUpdate = functions.firestore
  .document("feed/{userId}/feeditem/{feedItemId}")
  .onCreate(async (snap, context) => {
    const userId = context.params.userId;

    // Prepare the notification payload
    const payload = {
      notification: {
        title: "New Notification",
        body: "You have a new notification",
        sound: "default",
      },
    };

    // Retrieve the device token from Firestore
    const userDoc = await
    admin.firestore().collection("users").doc(userId).get();
    const deviceToken = userDoc.data()?.deviceToken;

    if (!deviceToken) {
      logger.warn("No device token found for user:", userId);
      return null;
    }

    // Send the notification to the device
    return admin.messaging().sendToDevice(deviceToken, payload);
  });
