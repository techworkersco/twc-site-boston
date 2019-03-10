'use strict';
const AWS                  = require('aws-sdk');
const awsServerlessExpress = require('aws-serverless-express');

const AWS_SECRET = process.env.AWS_SECRET;

const secretsmanager = new AWS.SecretsManager();

let server;

async function createServer(options) {
  // Get secret JSON
  const secret = await secretsmanager.getSecretValue(options).promise();

  // Update ENV
  Object.assign(process.env, JSON.parse(secret.SecretString));

  // Create server
  server = awsServerlessExpress.createServer(require('./app'));

  // Resolve server
  return server;
}

exports.handler = (event, context) => {
  console.log(`EVENT ${JSON.stringify(event)}`);
  Promise.resolve(server || createServer({SecretId: AWS_SECRET})).then((server) => {
    awsServerlessExpress.proxy(server, event, context);
  });
};
