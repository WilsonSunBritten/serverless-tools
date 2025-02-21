const admin = require('firebase-admin');

// Initialize Firebase Admin with service account
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
    }),
  });
}

module.exports.authenticate = async (event) => {
  try {
    const { idToken } = JSON.parse(event.body);

    // Verify Firebase token
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    
    return {
      statusCode: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Credentials': true,
      },
      body: JSON.stringify({
        token: idToken, // We can safely pass the Firebase token back as it's already verified
        user: {
          email: decodedToken.email,
          name: decodedToken.name,
          picture: decodedToken.picture
        }
      })
    };
  } catch (error) {
    console.error('Authentication error:', error);
    return {
      statusCode: 401,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Credentials': true,
      },
      body: JSON.stringify({
        error: 'Authentication failed',
        details: error.message
      })
    };
  }
};
