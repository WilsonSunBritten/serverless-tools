module.exports.demo = async (event) => {
  // Handle OPTIONS preflight request
  if (event.httpMethod === 'OPTIONS') {
    return {
      statusCode: 200,
      headers: {
        'Access-Control-Allow-Origin': 'https://cuddly-xylophone-q7xxvrqwr962w7x-8000.app.github.dev',
        'Access-Control-Allow-Credentials': true,
        'Access-Control-Allow-Methods': 'GET, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization, Origin, Accept',
      },
      body: ''
    };
  }

  const user = JSON.parse(event.requestContext.authorizer.user);
  
  return {
    statusCode: 200,
    headers: {
      'Access-Control-Allow-Origin': 'https://cuddly-xylophone-q7xxvrqwr962w7x-8000.app.github.dev',
      'Access-Control-Allow-Credentials': true,
      'Access-Control-Allow-Methods': 'GET, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization, Origin, Accept',
    },
    body: JSON.stringify({
      message: `Hello ${user.name}! This is a protected endpoint.`,
      timestamp: new Date().toISOString()
    })
  };
};
