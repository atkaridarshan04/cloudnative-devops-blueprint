import pino from "pino";

const logger = pino({
  level: process.env.LOG_LEVEL || "info",
  // In production containers, write plain JSON to stdout — Fluent Bit picks it up
  transport: process.env.NODE_ENV !== "production"
    ? { target: "pino-pretty" }   // human-readable in local dev
    : undefined,                   // raw JSON in production (container stdout)
});

export default logger;
