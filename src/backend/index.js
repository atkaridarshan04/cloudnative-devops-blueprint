import express from "express";
import { PORT, mongoDBURL } from "./config.js";
import mongoose from "mongoose";
import booksRoute from "./routes/booksRoute.js";
import cors from "cors";
import pinoHttp from "pino-http";
import logger from "./logger.js";

const app = express();

app.use(express.json());
app.use(cors());

// HTTP request/response logging middleware — logs method, url, status, responseTime
app.use(pinoHttp({ logger }));

app.get("/", (request, response) => {
  return response.status(200).send("Welcome to MERN Stack Book Shop - v3.0.0");
});

app.use("/books", booksRoute);

mongoose
  .connect(mongoDBURL)
  .then(() => {
    logger.info("Connected to MongoDB");
    app.listen(PORT, "0.0.0.0", () => {
      logger.info({ port: PORT }, "Server started");
    });
  })
  .catch((error) => {
    logger.fatal({ err: error }, "Failed to connect to MongoDB");
    process.exit(1);
  });
