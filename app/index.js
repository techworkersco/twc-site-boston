"use strict";
const awsServerlessExpress = require("aws-serverless-express");
const server = awsServerlessExpress.createServer(require("./app"));
exports.handler = (event, context) => {
  console.log(`EVENT ${JSON.stringify(event)}`);
  awsServerlessExpress.proxy(server, event, context);
};
