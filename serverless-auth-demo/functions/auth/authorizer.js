const admin = require('firebase-admin');

// Initialize Firebase Admin with service account if not already initialized
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
    }),
  });
}

module.exports.verify = async (event) => {
  try {
    console.log('Authorization token:', event.authorizationToken);
    const token = event.authorizationToken.replace('Bearer ', '');
    console.log('Extracted token:', token);
    const decodedToken = await admin.auth().verifyIdToken(token);
    console.log('Decoded token:', decodedToken);

    return {
      principalId: decodedToken.uid,
      policyDocument: {
        Version: '2012-10-17',
        Statement: [
          {
            Action: 'execute-api:Invoke',
            Effect: 'Allow',
            Resource: event.methodArn
          }
        ]
      },
      context: {
        user: JSON.stringify({
          email: decodedToken.email,
          name: decodedToken.name
        })
      }
    };
  } catch (error) {
    console.error('Token verification failed:', error);
    return {
      principalId: 'user',
      policyDocument: {
        Version: '2012-10-17',
        Statement: [
          {
            Action: 'execute-api:Invoke',
            Effect: 'Deny',
            Resource: event.methodArn
          }
        ]
      }
    };
  }
};
