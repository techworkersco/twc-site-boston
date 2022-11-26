"use strict";
const express = require("express");
const serverless = require("serverless-http");
const useragent = require("express-useragent");
const { google } = require("googleapis");

const BASE_PATH = process.env.BASE_PATH || "/";
const GOOGLE_API_KEY = process.env.GOOGLE_API_KEY;
const GOOGLE_CALENDAR_ID = process.env.GOOGLE_CALENDAR_ID;

const getGoogleUrl = (id) => {
  return `https://calendar.google.com/calendar/r?cid=${Buffer.from(id)
    .toString("base64")
    .replace(/\n|=+$/, "")}`;
};

const getWebcalUrl = (id) => {
  return `webcal://calendar.google.com/calendar/ical/${encodeURIComponent(
    id
  )}/public/basic.ics`;
};

const app = express();
const router = express.Router();
const gcal = google.calendar({ version: "v3", auth: GOOGLE_API_KEY });

router.get("/", (_, res) => {
  gcal.events.list({
    calendarId: GOOGLE_CALENDAR_ID,
    maxResults: 3,
    orderBy: "startTime",
    singleEvents: true,
    timeMin: new Date(),
  }).then((data) => {
    res.render("index", { events: data.data.items });
  });
});

router.get("/events", (req, res) => {
  res.redirect("/calendar");
});

router.get("/calendar", (_, res) => {
  res.render("calendar", { id: GOOGLE_CALENDAR_ID });
});

router.get("/calendar/google", (req, res) => {
  if (req.useragent.isMobile) {
    res.render("mobile", { id: GOOGLE_CALENDAR_ID });
  } else {
    res.redirect(getGoogleUrl(GOOGLE_CALENDAR_ID));
  }
});

router.get("/calendar/webcal", (_, res) => {
  res.redirect(getWebcalUrl(GOOGLE_CALENDAR_ID));
});

router.get("*", (req, res) => {
  res.redirect(`https://www.techworkerscoalition.org${req.originalUrl}`);
});

app.set("views", `${__dirname}/views`);
app.set("view engine", "ejs");
app.use(useragent.express());
app.use(BASE_PATH, router);

module.exports = app;
module.exports.handler = serverless(app);
