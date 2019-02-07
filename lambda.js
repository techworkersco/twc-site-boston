'use strict';
const AWS            = require('aws-sdk');
const express        = require('aws-serverless-express');
const secretsmanager = new AWS.SecretsManager();
const AWS_SECRET     = process.env.AWS_SECRET;

let server;

const createServer = (options) => {
  console.log('CREATE SERVER');
  return secretsmanager.getSecretValue(options).promise().then((res) => {

    // Update ENV
    Object.assign(process.env, JSON.parse(res.SecretString));

    // Create server
    server = express.createServer(require('./app'));

    // Resolve server
    return server;
  });
}

const getServer = (options) => {
  // Use cached server on warm start or create on cold start
  return Promise.resolve(server || createServer(options));
};

// Export Lambda handler
exports.handler = (event, context) => {
  console.log(`EVENT ${JSON.stringify(event)}`);
  getServer({SecretId: AWS_SECRET}).then((server) => express.proxy(server, event, context));
};
