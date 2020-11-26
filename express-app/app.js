var express = require("express");
var fetch = require("node-fetch");
var app = express();
FIB_ENDPOINT = process.env.FIB_ENDPOINT || "http://localhost:8000/fib";

app.get("/health", async (req, res) => {
  res.send(process.env.HEALTH_TOKEN == "bar" ? "OK" : "KO");
});

app.get("/hello", async (req, res) => {
  res.send("Hello World from Express!");
});

/**
 * Serves a random fib (not greater than the 40th)
 */
app.get("/random_fib", async (req, res, next) => {
  res = res.set({
    "Access-Control-Allow-Origin": "*",
  });

  try {
    const n = Math.round(Math.random() * 40);
    console.log(`Picked number ${n}`);
    const fibRes = await fetch(`${FIB_ENDPOINT}?n=${n}`);
    const result = await fibRes.text();

    res.send(result);
  } catch (error) {
    return next(error);
  }
});

// Listen
var port = process.env.PORT || 3000;
app.listen(port);
console.log("Listening on localhost:" + port);
