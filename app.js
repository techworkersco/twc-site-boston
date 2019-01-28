'use strict'
const express = require('express');
const fs      = require('fs');
const path    = require('path');
const app     = express();

app.use(express.static('./views'));
app.set('view engine', 'ejs');
app.get('/', (req, res) => res.render('index'));
app.get('*', (req, res) => res.redirect('/'));

module.exports = app;
