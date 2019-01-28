'use strict';
const app    = require('./app');
const aws    = require('aws-serverless-express');
const server = aws.createServer(app);
exports.handler = (event, context) => aws.proxy(server, event, context);
