# Default group builds everything in parallel
group "default" {
  targets = ["frontend", "backend"]
}

# ─────────── FRONTEND ───────────
target "frontend" {
  context    = "./src/frontend"
  dockerfile = "Dockerfile"

  platforms = [
    "linux/amd64",
    "linux/arm64",
  ]

  tags = [
    "bookstore-frontend:latest",
    "bookstore-frontend:v1",
  ]
}

# ─────────── BACKEND ───────────
target "backend" {
  context    = "./src/backend"
  dockerfile = "Dockerfile"

  platforms = [
    "linux/amd64",
    "linux/arm64",
  ]

  tags = [
    "bookstore-backend:latest",
    "bookstore-backend:v1",
  ]
}
