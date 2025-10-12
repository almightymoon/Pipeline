# 🔄 Using Your Pipeline with Other Repositories

## Overview

Your pipeline can process any repository! Here are several ways to use it with different projects, including datasets.

---

## 🚀 Method 1: Copy Workflow to Another Repo (Recommended)

### For Dataset Processing

1. **In your dataset repository**, create the workflow structure:

```bash
cd /path/to/your-dataset-repo
mkdir -p .github/workflows
```

2. **Copy the workflow file**:

```bash
cp /path/to/pipeline/.github/workflows/basic-pipeline.yml .github/workflows/
```

3. **Customize for your dataset**:

```yaml
# .github/workflows/dataset-pipeline.yml
name: 📊 Dataset Processing Pipeline

on:
  push:
    branches: [ main ]
  workflow_dispatch:

env:
  REGISTRY: harbor.yourcompany.com
  IMAGE_NAME: your-org/dataset-processor

jobs:
  validate-dataset:
    name: 🔍 Validate Dataset
    runs-on: ubuntu-latest
    
    steps:
    - name: 📥 Checkout Dataset
      uses: actions/checkout@v4
    
    - name: 🐍 Setup Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.11'
    
    - name: 📦 Install Dependencies
      run: |
        pip install pandas numpy scikit-learn jsonschema
    
    - name: 🔍 Validate Dataset Schema
      run: |
        python scripts/validate_dataset.py
        echo "✅ Dataset validation passed"
    
    - name: 📊 Generate Dataset Statistics
      run: |
        python scripts/generate_stats.py
        echo "✅ Statistics generated"

  process-dataset:
    name: 🔄 Process Dataset
    runs-on: ubuntu-latest
    needs: validate-dataset
    
    steps:
    - name: 📥 Checkout Code
      uses: actions/checkout@v4
    
    - name: 🐍 Setup Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.11'
    
    - name: 📦 Install Processing Tools
      run: |
        pip install -r requirements.txt
    
    - name: 🔄 Transform Dataset
      run: |
        python scripts/transform_dataset.py \
          --input data/raw/ \
          --output data/processed/ \
          --format json
    
    - name: 📤 Upload Processed Data
      uses: actions/upload-artifact@v4
      with:
        name: processed-dataset
        path: data/processed/
        retention-days: 30

  deploy-dataset:
    name: 🚀 Deploy to Kubernetes
    runs-on: ubuntu-latest
    needs: process-dataset
    
    steps:
    - name: 📥 Checkout Code
      uses: actions/checkout@v4
    
    - name: ☸️ Setup Kubectl
      uses: azure/setup-kubectl@v3
      with:
        version: 'latest'
    
    - name: 🔐 Configure Kubernetes Access
      run: |
        echo "${{ secrets.KUBECONFIG }}" | base64 -d > $HOME/kubeconfig
        echo "KUBECONFIG=$HOME/kubeconfig" >> $GITHUB_ENV
    
    - name: 📊 Deploy Dataset to Cluster
      run: |
        kubectl create configmap dataset-processed \
          --from-file=data/processed/ \
          --namespace=ml-pipeline \
          --dry-run=client -o yaml | kubectl apply -f -
```

4. **Set up GitHub secrets** in your dataset repo:

```bash
cd /path/to/your-dataset-repo
gh auth login

# Copy secrets from main pipeline
gh secret set KUBECONFIG --body "$(gh secret list -R your-org/pipeline | grep KUBECONFIG)"
```

---

## 🔗 Method 2: Trigger Pipeline from External Repo

Use `repository_dispatch` to trigger your main pipeline from other repos:

### In Your Main Pipeline Repo

Update `.github/workflows/basic-pipeline.yml`:

```yaml
on:
  push:
    branches: [ main ]
  repository_dispatch:
    types: [process-external-repo]
  workflow_dispatch:
    inputs:
      repo_url:
        description: 'External repository URL'
        required: true
        type: string
      repo_branch:
        description: 'Branch to process'
        required: false
        default: 'main'
        type: string

jobs:
  clone-external-repo:
    name: 📥 Clone External Repository
    runs-on: ubuntu-latest
    
    steps:
    - name: 📥 Clone External Repo
      run: |
        git clone ${{ github.event.inputs.repo_url || github.event.client_payload.repo_url }} external-repo
        cd external-repo
        git checkout ${{ github.event.inputs.repo_branch || github.event.client_payload.repo_branch || 'main' }}
    
    - name: 📤 Upload External Code
      uses: actions/upload-artifact@v4
      with:
        name: external-repo
        path: external-repo/
```

### From Your Dataset Repo

Trigger the main pipeline:

```bash
# Using GitHub API
curl -X POST \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/your-org/pipeline/dispatches \
  -d '{
    "event_type": "process-external-repo",
    "client_payload": {
      "repo_url": "https://github.com/your-org/dataset-repo.git",
      "repo_branch": "main"
    }
  }'
```

---

## 📦 Method 3: Create Reusable Workflow

Create a reusable workflow that any repo can call:

### In Main Pipeline Repo

Create `.github/workflows/reusable-dataset-pipeline.yml`:

```yaml
name: 🔄 Reusable Dataset Pipeline

on:
  workflow_call:
    inputs:
      dataset-path:
        required: true
        type: string
      output-format:
        required: false
        type: string
        default: 'json'
      python-version:
        required: false
        type: string
        default: '3.11'
    secrets:
      KUBECONFIG:
        required: true

jobs:
  process-dataset:
    runs-on: ubuntu-latest
    
    steps:
    - name: 📥 Checkout Code
      uses: actions/checkout@v4
    
    - name: 🐍 Setup Python
      uses: actions/setup-python@v4
      with:
        python-version: ${{ inputs.python-version }}
    
    - name: 📊 Process Dataset
      run: |
        echo "Processing dataset at: ${{ inputs.dataset-path }}"
        echo "Output format: ${{ inputs.output-format }}"
        # Add your processing logic
    
    - name: 🚀 Deploy to Kubernetes
      run: |
        echo "${{ secrets.KUBECONFIG }}" | base64 -d > $HOME/kubeconfig
        export KUBECONFIG=$HOME/kubeconfig
        kubectl get nodes
```

### In Your Dataset Repo

Call the reusable workflow:

```yaml
# .github/workflows/use-pipeline.yml
name: 📊 Process Dataset

on:
  push:
    branches: [ main ]

jobs:
  process:
    uses: your-org/pipeline/.github/workflows/reusable-dataset-pipeline.yml@main
    with:
      dataset-path: 'data/raw/'
      output-format: 'json'
      python-version: '3.11'
    secrets:
      KUBECONFIG: ${{ secrets.KUBECONFIG }}
```

---

## 🎯 Method 4: Dataset-Specific Pipeline

Create a complete dataset processing pipeline:

<function_calls>
<invoke name="$FUNCTION_NAME">
<parameter name="$PARAMETER_NAME">$PARAMETER_VALUE
