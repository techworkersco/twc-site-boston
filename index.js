'use strict';

// Run locally
if (require.main === module) {
  require('dotenv').config();
  const app  = require('./website/app');
  const PORT = process.env.PORT || 3000;
  app.listen(PORT, () => console.log(`> Listening on port ${PORT}`));
}

// Run as Lambda
else {
  exports.handler = require('./website/lambda').handler;
}
