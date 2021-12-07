"use strict";
require("dotenv").config({ path: `${__dirname}/../.env` });
const app = require("./index");
const PORT = process.env.PORT || 3000;
const BASE_PATH = process.env.BASE_PATH || "/";
app.listen(PORT, () =>
  console.log(`=> Listening at http://localhost:${PORT}${BASE_PATH}`)
);
