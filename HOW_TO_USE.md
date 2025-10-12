# 🎯 How to Process Your Dataset Through the Pipeline

## ✅ Your Pipeline is Ready!

You now have a **fully automated dataset processing pipeline** that can process datasets from ANY GitHub repository!

---

## 🚀 Quick Method - Web Interface (Easiest!)

### Step-by-Step:

1. **Open GitHub Actions** in your browser:
   ```
   https://github.com/almightymoon/Pipeline/actions
   ```

2. **Find the workflow**:
   - Look for "📊 Dataset Processing Pipeline" in the list
   - Click on it

3. **Click "Run workflow" button** (top right, green button)

4. **Fill in the form**:
   - **Use workflow from**: `main`
   - **dataset_repo**: `https://github.com/YOUR-USERNAME/YOUR-DATASET.git`
   - **dataset_branch**: `main`
   - **dataset_format**: `json` (or `csv`, `parquet`)

5. **Click the green "Run workflow" button**

6. **Wait 2-3 minutes** for completion

7. **Download your processed dataset**:
   - Click on the completed workflow run
   - Scroll down to "Artifacts"
   - Download "processed-dataset"

**That's it!** ✅

---

## 💻 Command Line Method

```bash
# Navigate to your pipeline directory
cd /Users/moon/Documents/pipeline

# Run the dataset processing workflow
gh workflow run dataset-pipeline.yml \
  -f dataset_repo="https://github.com/YOUR-ORG/YOUR-DATASET.git" \
  -f dataset_branch="main" \
  -f dataset_format="json"

# Watch progress
sleep 5 && gh run watch

# When complete, download results
gh run download
```

---

## 📊 What Gets Processed?

The pipeline will:

### 1. Fetch Your Dataset ✅
- Clones your dataset repository
- Checks out the specified branch
- Scans for data files

### 2. Validate ✅
- Checks data schema
- Validates structure
- Generates quality report
- Identifies issues (nulls, duplicates, etc.)

### 3. Process & Clean ✅
- Removes null values
- Removes duplicates
- Normalizes data (if requested)
- Converts between formats

### 4. Deploy to Kubernetes ✅
- Creates ConfigMap with processed data
- Makes it available to ML training jobs
- Accessible from any pod in the cluster

### 5. Generate Reports ✅
- Processing summary
- Quality metrics
- Statistics and insights

---

## 📦 What You Get

### Artifacts (downloadable from GitHub):
```
processed-dataset/
├── processed.csv        ← CSV format
├── processed.json       ← JSON format
├── processed.parquet    ← Parquet format (efficient!)
└── statistics.json      ← Dataset stats
```

### In Kubernetes:
```bash
# List all processed datasets
kubectl get configmaps -n ml-pipeline -l app=dataset-processor

# Get a specific dataset
kubectl get configmap processed-dataset-20251012 -n ml-pipeline -o yaml
```

---

## 🎓 Real Examples

### Example 1: Process Your CSV Dataset

```bash
gh workflow run dataset-pipeline.yml \
  -f dataset_repo="https://github.com/your-username/sales-data.git" \
  -f dataset_format="csv"
```

### Example 2: Process JSON API Data

```bash
gh workflow run dataset-pipeline.yml \
  -f dataset_repo="https://github.com/your-username/api-responses.git" \
  -f dataset_format="json"
```

### Example 3: Process from Different Branch

```bash
gh workflow run dataset-pipeline.yml \
  -f dataset_repo="https://github.com/your-username/dataset.git" \
  -f dataset_branch="experimental" \
  -f dataset_format="parquet"
```

---

## 🔍 Monitor Progress

### GitHub Actions:
- https://github.com/almightymoon/Pipeline/actions

### Grafana:
- http://213.109.162.134:30102 (admin/admin123)

### Kubernetes:
```bash
ssh ubuntu@213.109.162.134
# Password: qwert1234

kubectl get pods -n ml-pipeline
kubectl get configmaps -n ml-pipeline -l app=dataset-processor
```

---

## 💡 Pro Tips

1. **Test Locally First**: Use `scripts/validate_dataset.py`
2. **Large Datasets**: Use Git LFS
3. **Private Repos**: Add Personal Access Token as secret
4. **Batch Processing**: Process multiple datasets by running workflow multiple times

---

## 📚 More Documentation

- [QUICK_START.md](QUICK_START.md) - Quick reference
- [docs/DATASET_PROCESSING_GUIDE.md](docs/DATASET_PROCESSING_GUIDE.md) - Complete guide
- [docs/USING_PIPELINE_WITH_OTHER_REPOS.md](docs/USING_PIPELINE_WITH_OTHER_REPOS.md) - Advanced usage

---

**Ready to process your dataset!** 🚀

