# ⚡ Quick Start Guide

## 🎯 Test Your Pipeline with a Dataset in 3 Steps

### Step 1: Go to GitHub Actions

```
https://github.com/your-org/pipeline/actions/workflows/dataset-pipeline.yml
```

### Step 2: Click "Run workflow"

Enter:
- **dataset_repo**: `https://github.com/your-org/your-dataset.git`
- **dataset_branch**: `main`
- **dataset_format**: `json` (or `csv`, `parquet`)

### Step 3: Click "Run workflow" button

✅ **Done!** Your dataset will be:
1. Fetched from the repo
2. Validated
3. Processed & cleaned
4. Deployed to Kubernetes
5. Available as artifacts

---

## 🖥️ Using Command Line

```bash
# Make sure you're in your pipeline repo
cd /Users/moon/Documents/pipeline

# Trigger dataset processing
gh workflow run dataset-pipeline.yml \
  -f dataset_repo="https://github.com/your-org/your-dataset.git" \
  -f dataset_branch="main" \
  -f dataset_format="json"

# Watch the run
gh run watch

# Download processed dataset
gh run download
```

---

## 📦 What You'll Get

After the pipeline completes:

### Artifacts (Downloadable)
- `raw-dataset/` - Original dataset
- `processed-dataset/` - Cleaned & transformed data
  - `processed.csv` - CSV format
  - `processed.json` - JSON format  
  - `processed.parquet` - Parquet format
  - `statistics.json` - Dataset statistics
- `quality-report/` - Quality metrics
- `processing-report.md` - Summary report

### Kubernetes ConfigMap
```bash
# View deployed dataset
kubectl get configmaps -n ml-pipeline -l app=dataset-processor

# Download dataset from cluster
kubectl get configmap processed-dataset-20251012 -n ml-pipeline -o json | \
  jq -r '.data["processed.json"]' > my-dataset.json
```

---

## 🎓 Example Datasets to Try

### 1. Your Own Dataset

```bash
gh workflow run dataset-pipeline.yml \
  -f dataset_repo="https://github.com/YOUR-USERNAME/YOUR-DATASET.git" \
  -f dataset_format="csv"
```

### 2. Public Dataset

```bash
gh workflow run dataset-pipeline.yml \
  -f dataset_repo="https://github.com/datasets/covid-19.git" \
  -f dataset_format="csv"
```

### 3. Hugging Face Dataset

```bash
gh workflow run dataset-pipeline.yml \
  -f dataset_repo="https://huggingface.co/datasets/imdb" \
  -f dataset_format="json"
```

---

## 🔧 Current Server Setup

**Your Kubernetes Cluster**: `213.109.162.134`

### Access Points:
- **Grafana**: http://213.109.162.134:30102 (admin/admin123)
- **ArgoCD**: http://213.109.162.134:32146 (admin/AcfOP4fSGVt-4AAg)
- **Jira**: https://faniqueprimus.atlassian.net/browse/KAN

### Check Dataset Processing:

```bash
# SSH to your server
ssh ubuntu@213.109.162.134
# Password: qwert1234

# Check deployed datasets
kubectl get configmaps -n ml-pipeline -l app=dataset-processor

# Check pipeline pods
kubectl get pods -n ml-pipeline

# View Grafana dashboards
# Open: http://213.109.162.134:30102
```

---

## 🎯 Next Steps

1. **Try it now**: Run the workflow with your dataset!
2. **View in Grafana**: Monitor the processing metrics
3. **Check Kubernetes**: See the deployed configmaps
4. **Download Results**: Get your processed dataset

---

## 🆘 Need Help?

- 📚 Full Guide: [docs/DATASET_PROCESSING_GUIDE.md](DATASET_PROCESSING_GUIDE.md)
- 🔧 Pipeline Guide: [docs/COMPLETE_PIPELINE_GUIDE.md](COMPLETE_PIPELINE_GUIDE.md)
- 🐛 Issues: Check GitHub Actions logs

**Ready to process your dataset!** 🚀

