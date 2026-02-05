# MERN DevOps Project

This project is designed to facilitate the deployment of a MERN (MongoDB, Express, React, Node.js) application by integrating key DevOps tools and best practices. It leverages Docker for containerization, Kubernetes for orchestration, Jenkins for CI/CD automation, Helm for package management, ArgoCD for GitOps-based deployment, Kustomize for environment-specific configurations, and Prometheus/Grafana for monitoring and observability.

---

## Overview

The MERN DevOps project includes:

- **Dockerization**: Building and running containers for the frontend, backend, and MongoDB using Docker and Docker Compose.

- **Kubernetes Deployment**: Deploying the application on a kind Kubernetes cluster and configuring an ingress controller.

- **CI/CD Pipeline**: Automating multiple SDLC stages using Jenkins.

- **Helm Deployment**: Managing Kubernetes deployments using Helm charts for MongoDB, backend, and frontend services.

- **ArgoCD GitOps**: Continuously deploying and synchronizing the application with the GitHub repository.

- **Kustomize**: Managing Kubernetes configurations for different environments without modifying base YAML files.

- **Observability**: Implementing monitoring mechanisms using tools like Prometheus and Grafana to monitor the health and performance of the application.

---

## Project Deployment Flow

![workflow-gif](./docs/assets/workflow.gif)

---

## Documentation

To understand the various components of this project, refer to the following documentation:

- **[Docker.md](./docs/Docker.md)**:  
  Detailed instructions on how to build and run the MERN stack application using Docker, including creating a Docker network, building images, and managing containers.

- **[Kubernetes.md](./docs/Kubernetes.md)**:  
  Detailed instructions on deploying the MERN stack application using Kubernetes, including how to set up persistent storage, deploy services, and access the application.

- **[Jenkins.md](./docs/Jenkins.md)**:  
  A comprehensive guide on the Jenkins CI/CD pipeline, outlining the various stages, parameters, prerequisites, and tools used to automate the integration and deployment processes.

- **[Helm.md](./docs/Helm.md)**:  
  Instructions on how to deploy the MERN stack application using Helm, including installation, chart customization, and deployment of MongoDB, backend, and frontend services.

- **[ArgoCD.md](./docs/ArgoCD.md)**:  
  A step-by-step guide on installing, configuring, and using ArgoCD to deploy the application by connecting ArgoCD to the GitHub repository.

- **[Kustomize.md](./docs/Kustomize.md)**:  
  Steps on how to manage multiple environments (Dev, Prod) using Kustomize for Kubernetes configurations.

- **[Observability.md](./docs/Observability.md)**:  
  Instructions on setting up Prometheus for monitoring application metrics and visualizing data with Grafana dashboards.

---

## 💡 Important: Note on Frontend Environment Variables

Depending on the branch you are using, the handling of environment variables (specifically the Backend URL) differs:

- **Beginner Branch (Dev Mode)**: Uses a `Dockerfile` with `npm run dev`. This allows the application to read Kubernetes **ConfigMaps at runtime**. The live Vite server injects variables directly from the Pod's shell into the browser.
- **Main Branch (Production Mode)**: Uses a `Dockerfile` with a multi-stage **Nginx build**. Since Nginx serves static files, environment variables are **hard-coded into the JS at build-time**. 
- **Best Practice**: In production, we use `VITE_API_BACKEND_URL=""`. This enables **relative path routing**, allowing the **Ingress Controller** or **Gateway API** to route traffic to the backend without requiring manual IP/Port injection into the static assets.
---