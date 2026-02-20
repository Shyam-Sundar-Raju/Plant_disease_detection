# CI/CD Pipeline Overview

This project uses **GitHub Actions** for Continuous Integration and Continuous Deployment.

## 🚀 Workflows

### 1. Backend CI (`backend.yml`)
- **Trigger**: Every push or pull request to the `main` branch that modifies files in the `backend/` directory.
- **Jobs**:
  - **Linting**: Checks code quality using `flake8`.
  - **Testing**: Runs the FastAPI test suite using `pytest`.
    - Automatically spins up a **MongoDB 6.0** service container.
    - Sets up necessary environment variables for testing.
  - **Docker Build**: Verifies that the `Dockerfile` builds correctly (on `main` push).

### 2. Frontend CI (`frontend.yml`)
- **Trigger**: Every push or pull request to the `main` branch that modifies files in the `frontend/` directory.
- **Jobs**:
  - **Analyze**: Runs `flutter analyze` and checks for formatting issues.
  - **Testing**: Runs Flutter unit and widget tests.
  - **Web Build**: Builds a web version of the application to ensure build success.

### 3. Production Release (`release.yml`)
- **Trigger**: Every time a new tag starting with `v` is pushed (e.g., `git tag v1.0.0 && git push --tags`).
- **Jobs**:
  - **Build APK**: Compiles the Flutter app into a release APK.
  - **GitHub Release**: Automatically creates a new Release on GitHub and uploads the APK as an artifact.
  - **Docker Image**: Builds the production-ready Docker image for the backend.

## 🛠️ How to use

### Local Formatting
Before pushing, it's recommended to format your code:
- **Backend**: `black .` inside the `backend` folder.
- **Frontend**: `dart format .` inside the `frontend` folder.

### Triggering a Release
To trigger the production pipeline and generate an APK:
1. Update version in `frontend/pubspec.yaml`.
2. Commit your changes.
3. Tag the commit: `git tag v1.0.0`
4. Push tags: `git push origin --tags`

## 🔐 Secrets Required
For the "Production Release" to fully work (e.g., pushing to Docker Hub), you should add the following to your GitHub Repository Secrets:
- `DOCKERHUB_USERNAME` (Optional, if you want to push)
- `DOCKERHUB_TOKEN` (Optional, if you want to push)
