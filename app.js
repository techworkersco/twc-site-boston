'use strict';
const express   = require('express');
const fs        = require('fs');
const path      = require('path');
const useragent = require('express-useragent');
const {google}  = require('googleapis');

const GOOGLE_API_KEY     = process.env.GOOGLE_API_KEY;
const GOOGLE_CALENDAR_ID = process.env.GOOGLE_CALENDAR_ID;

const getGoogleUrl = (id) => {
  var cid = Buffer.from(id).toString('base64').replace(/\n|=+$/, '');
  return `https://calendar.google.com/calendar/r?cid=${cid}`;
}

const getWebcalUrl = (id) => {
  var eid = encodeURIComponent(id);
  return `webcal://calendar.google.com/calendar/ical/${eid}/public/basic.ics`;
}

const app  = express();
const gcal = google.calendar({version: 'v3', auth: GOOGLE_API_KEY});

app.use(useragent.express());
app.use(express.static('./views'));
app.set('view engine', 'ejs');

app.get('/', (req, res) => {
  gcal.events.list({
    calendarId:   GOOGLE_CALENDAR_ID,
    maxResults:   3,
    orderBy:      'startTime',
    singleEvents: true,
    timeMin:      new Date(),
  }).then((data) => {
    res.render('index', {events: data.data.items});
  });
});

app.get('/calendar', (req, res) => {
  res.render('calendar', {id: GOOGLE_CALENDAR_ID});
});

app.get('/calendar/google', (req, res) => {
  if (req.useragent.isMobile) {
    res.render('mobile', {id: GOOGLE_CALENDAR_ID});
  } else {
    res.redirect(getGoogleUrl(GOOGLE_CALENDAR_ID));
  }
});

app.get('/calendar/webcal', (req, res) => {
  res.redirect(getWebcalUrl(GOOGLE_CALENDAR_ID));
});

app.get('*', (req, res) => res.redirect('/'));

module.exports = app;
