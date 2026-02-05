# ────────────── Stage 1: Build ──────────────
FROM node:22 AS base
WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .

# ────────────── Stage 2 ──────────────
FROM node:20-slim
WORKDIR /app

# Create a non-root user
RUN adduser --disabled-password --gecos "" appuser

# Copy only what's needed
COPY --from=base /app ./

# COPY and set the env file
COPY .env.docker .env

# Use production mode
ENV NODE_ENV=production

# Remove devDependencies
RUN npm prune --omit=dev

# Install curl for healthcheck support
# RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Update Permissions
RUN chown -R appuser:appuser /app
USER appuser

EXPOSE 8000
CMD ["npm", "start"]