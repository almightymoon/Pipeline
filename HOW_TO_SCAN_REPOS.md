# How to Scan External Repositories

## Overview
This pipeline can automatically scan any external repository without needing to set up the pipeline in that repository. Perfect for:
- Scanning incoming code submissions
- Security auditing third-party repositories
- Quality checking vendor code
- Evaluating open-source projects before use

---

## Quick Start

### Step 1: Add Repository to Scan

Edit `repos-to-scan.yaml` and add your repository:

```yaml
repositories:
  - url: https://github.com/username/repo-to-scan
    name: my-project
    branch: main
    scan_type: full
```

### Step 2: Commit and Push

```bash
git add repos-to-scan.yaml
git commit -m "Add repository to scan"
git push
```

### Step 3: Watch the Scan

The pipeline will automatically:
1. Clone the repository
2. Run security scans
3. Check for secrets
4. Analyze dependencies
5. Test builds (if applicable)
6. Generate a report

View results at: https://github.com/almightymoon/Pipeline/actions

---

## Configuration Options

### Scan Types

#### `full` (Default)
Complete analysis including:
- Security vulnerability scan (Trivy)
- Secret detection
- Dependency analysis
- Code quality checks
- Build testing
- Jira issue creation

```yaml
- url: https://github.com/example/full-scan
  name: complete-check
  scan_type: full
```

#### `security-only`
Fast security-focused scan:
- Vulnerability scanning
- Secret detection
- Critical issues only

```yaml
- url: https://github.com/example/quick-security
  name: security-check
  scan_type: security-only
```

#### `quick`
Basic fast scan:
- File structure analysis
- Dependency check
- Secret detection

```yaml
- url: https://github.com/example/quick-check
  name: fast-scan
  scan_type: quick
```

---

## Examples

### Example 1: Scan Multiple Repositories

```yaml
repositories:
  - url: https://github.com/company/frontend-app
    name: frontend
    branch: main
    scan_type: full
  
  - url: https://github.com/company/backend-api
    name: backend
    branch: develop
    scan_type: full
  
  - url: https://github.com/vendor/library
    name: third-party-lib
    branch: master
    scan_type: security-only
```

### Example 2: Quick Security Check

```yaml
repositories:
  - url: https://github.com/suspicious/repo
    name: security-audit
    scan_type: security-only
```

### Example 3: Scan Private Repository

For private repositories, add a GitHub token:

1. Create a Personal Access Token: https://github.com/settings/tokens
2. Add as secret: `GH_SCAN_TOKEN`
3. Use in URL: `https://x-access-token:${{ secrets.GH_SCAN_TOKEN }}@github.com/private/repo`

---

## What Gets Scanned

### Security Analysis
- ✅ CVE vulnerabilities in dependencies
- ✅ Exposed secrets (API keys, passwords, tokens)
- ✅ Hardcoded credentials
- ✅ Security misconfigurations

### Code Quality
- ✅ TODO/FIXME comments
- ✅ Large files (>1MB)
- ✅ Code structure
- ✅ Dependency health

### Build Testing
- ✅ Dockerfile builds
- ✅ Python package installation
- ✅ Node.js dependency resolution
- ✅ Go module verification

---

## Viewing Results

### GitHub Actions
1. Go to: https://github.com/almightymoon/Pipeline/actions
2. Click on "Scan External Repositories" workflow
3. Select the latest run
4. View detailed logs for each repository

### Jira (if configured)
Each scan creates a Jira issue in your KAN project with:
- Repository name and URL
- Scan summary
- Link to detailed results

---

## Scheduling

### Automatic Scans

The workflow runs automatically:
- ✅ When `repos-to-scan.yaml` is updated
- ✅ Daily at midnight (scheduled)
- ✅ Manual trigger via GitHub Actions UI

### Manual Trigger

```bash
gh workflow run scan-external-repos.yml
```

---

## Best Practices

### 1. Start with Security-Only
For unknown repositories, start with `security-only` scan:
```yaml
scan_type: security-only
```

### 2. Use Descriptive Names
Make it easy to identify repositories:
```yaml
name: vendor-payment-lib-v2.1
```

### 3. Specify Branches
Always specify the branch to scan:
```yaml
branch: main  # or develop, master, etc.
```

### 4. Review Results
Check scan results before:
- Integrating third-party code
- Deploying to production
- Sharing with team

### 5. Regular Scanning
Add important repositories to scan daily:
- Dependencies
- Vendor code
- Open-source libraries

---

## Troubleshooting

### Issue: "Repository not found"
- **Solution**: Check URL format and access permissions
- For private repos, add authentication token

### Issue: "Build failed"
- **Solution**: This is non-blocking, just informational
- Review the logs to understand build requirements

### Issue: "Scan too slow"
- **Solution**: Use `security-only` or `quick` scan type
- Reduce number of parallel scans (max-parallel: 1)

---

## Security Considerations

### What Gets Scanned
- ✅ Code and configuration files
- ✅ Dependencies and manifests
- ✅ Dockerfiles and build scripts

### What Doesn't Get Scanned
- ❌ Binary files
- ❌ Git history
- ❌ Large media files
- ❌ Build artifacts

### Data Privacy
- Repository code is cloned temporarily during scan
- No code is stored or persisted
- Results contain only summary information
- Full logs available only to authorized users

---

## Support

For issues or questions:
1. Check GitHub Actions logs
2. Review Jira issues
3. See `CURRENT_SETUP.md` for pipeline details

---

*Last updated: October 13, 2025*

