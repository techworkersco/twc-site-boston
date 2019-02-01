'use strict';
const AWS            = require('aws-sdk');
const express        = require('aws-serverless-express');
const secretsmanager = new AWS.SecretsManager();
const AWS_SECRET     = process.env.AWS_SECRET;

let server;

const createServer = (options) => {
  return secretsmanager.getSecretValue(options).promise().then((res) => {

    // Update ENV
    Object.assign(process.env, JSON.parse(res.SecretString));

    // Import express app
    const app = require('./app');

    // Create server
    server = express.createServer(app);
    return server;
  });
}

const getServer = () => {

  // Create server on cold start
  if (server === undefined) {
    return createServer({SecretId: AWS_SECRET});
  }

  // Use cached server on warm start
  return Promise.resolve(server);
};

// Export Lambda handler
exports.handler = (event, context) => {
  getServer().then((server) => express.proxy(server, event, context));
};
