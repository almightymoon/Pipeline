# How to Add Docker Hub Secrets to GitHub

## Important Security Note
⚠️ NEVER commit credentials to the repository!

Instead, add them as GitHub Secrets.

## Steps to Add Docker Hub Credentials

### 1. Go to Your GitHub Repository
Navigate to: https://github.com/almightymoon/Pipeline

### 2. Open Settings → Secrets and Variables → Actions
URL: https://github.com/almightymoon/Pipeline/settings/secrets/actions

### 3. Click "New repository secret"

### 4. Add First Secret: DOCKER_USERNAME
- **Name:** `DOCKER_USERNAME`
- **Secret:** `arthurjones`
- Click "Add secret"

### 5. Add Second Secret: DOCKER_PASSWORD
- **Name:** `DOCKER_PASSWORD`
- **Secret:** `dckr_pat_CU-5p9b569a9PbZkwBoz3HJz4xk`
- Click "Add secret"

## Verification
Your secrets page should show:
- ✅ DOCKER_USERNAME
- ✅ DOCKER_PASSWORD

## Usage
These secrets will be automatically used by the workflow when it runs.
The workflow will use them to:
1. Login to Docker Hub
2. Push Docker images
3. Tag images with your username

## Security Reminder
- These credentials are stored securely in GitHub
- They are never exposed in logs or commits
- Only authorized GitHub Actions can use them
