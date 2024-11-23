const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

admin.initializeApp();

// Configure your email service (Gmail example)
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: 'your-email@gmail.com',
    // Use App Password if using Gmail
    // https://support.google.com/accounts/answer/185833?hl=en
    pass: 'your-app-password'
  }
});

exports.sendEmail = functions.https.onCall(async (data, context) => {
  try {
    // Verify authentication if needed
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { toEmail, message, toName } = data;

    const mailOptions = {
      from: 'HomeMaster <your-email@gmail.com>',
      to: toEmail,
      subject: 'HomeMaster Announcement',
      text: message,
      html: message.replace(/\n/g, '<br>')
    };

    await transporter.sendMail(mailOptions);

    return { success: true };
  } catch (error) {
    console.error('Error sending email:', error);
    throw new functions.https.HttpsError('internal', 'Error sending email');
  }
});

// Optional: Batch email function
exports.sendBatchEmails = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { message } = data;
    
    // Get all users with emails
    const usersSnapshot = await admin.firestore()
      .collection('users')
      .where('email', '!=', null)
      .get();

    const results = {
      successCount: 0,
      failureCount: 0,
      totalRecipients: usersSnapshot.size
    };

    for (const doc of usersSnapshot.docs) {
      const userData = doc.data();
      if (userData.email) {
        try {
          await transporter.sendMail({
            from: 'HomeMaster <your-email@gmail.com>',
            to: userData.email,
            subject: 'HomeMaster Announcement',
            text: message,
            html: message.replace(/\n/g, '<br>')
          });
          results.successCount++;
          
          // Add delay to avoid rate limits
          await new Promise(resolve => setTimeout(resolve, 1000));
        } catch (error) {
          console.error(`Failed to send to ${userData.email}:`, error);
          results.failureCount++;
        }
      }
    }

    return results;
  } catch (error) {
    console.error('Error in batch send:', error);
    throw new functions.https.HttpsError('internal', 'Error sending batch emails');
  }
});
