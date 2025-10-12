# ⚡ Simple Usage Guide - Process Repos by Just Editing a File!

## 🎯 The Easiest Way to Process Any Repository

Just edit one file, push, and the pipeline does everything automatically!

---

## 📝 Step 1: Edit `repos-to-process.yaml`

Open the file `repos-to-process.yaml` and add your repository:

```yaml
repositories:
  # Add your dataset repository
  - repo: https://github.com/your-username/your-dataset.git
    branch: main
    type: dataset
    format: json
```

**That's it!** The pipeline will auto-detect if you don't specify `type` and `format`.

---

## 🚀 Step 2: Push the File

```bash
cd /Users/moon/Documents/pipeline

# Edit the file
nano repos-to-process.yaml
# Or use your favorite editor

# Commit and push
git add repos-to-process.yaml
git commit -m "Add dataset to process"
git push
```

---

## ✨ Step 3: Watch It Run!

The pipeline **automatically triggers** and:
- ✅ Reads your repos-to-process.yaml file
- ✅ Clones each repository you listed
- ✅ Auto-detects if it's a dataset or code
- ✅ Processes accordingly
- ✅ Uploads results as artifacts
- ✅ Deploys to Kubernetes (if dataset)

---

## 📊 Examples

### Example 1: Single Dataset

```yaml
repositories:
  - repo: https://github.com/my-org/sales-data.git
```

Push → Pipeline auto-detects it's CSV data → Processes it!

### Example 2: Multiple Datasets

```yaml
repositories:
  - repo: https://github.com/my-org/dataset-1.git
    format: csv
    
  - repo: https://github.com/my-org/dataset-2.git
    format: json
    
  - repo: https://github.com/my-org/dataset-3.git
    branch: experimental
    format: parquet
```

Push → All 3 datasets process in parallel!

### Example 3: Mix of Dataset and Code

```yaml
repositories:
  - repo: https://github.com/my-org/my-dataset.git
    type: dataset
    
  - repo: https://github.com/my-org/my-app.git
    type: code
```

Push → Dataset gets processed, code gets tested!

---

## 🎯 Auto-Detection Rules

If you don't specify `type`, the pipeline will:

### **Classify as DATASET** if:
- More data files (CSV/JSON/Parquet) than code files
- Contains `.csv`, `.json`, or `.parquet` files

### **Classify as CODE** if:
- More Python/JavaScript/Java files
- Contains typical code structure

---

## 📦 What You Get

After pushing, check:

### 1. GitHub Actions:
```
https://github.com/almightymoon/Pipeline/actions
```
Look for: "🔄 Auto Process Repositories"

### 2. Download Artifacts:
- Click on the completed run
- Scroll to "Artifacts"
- Download: `processed-[repo-name]-[run-number]`

### 3. Kubernetes (for datasets):
```bash
ssh ubuntu@213.109.162.134
kubectl get configmaps -n ml-pipeline -l app=dataset-processor
```

---

## 🔥 Super Simple Workflow

```bash
# 1. Edit file
nano repos-to-process.yaml

# 2. Add your repo URL
repositories:
  - repo: https://github.com/you/your-dataset.git

# 3. Save, commit, push
git add repos-to-process.yaml
git commit -m "Process my dataset"
git push

# 4. Done! Check GitHub Actions
```

**That's literally it!** 🎉

---

## 💡 Pro Tips

### Tip 1: Process Multiple at Once
Add multiple repos to the file - they process in parallel!

### Tip 2: Leave Comments
```yaml
repositories:
  # Customer data from Q4 2024
  - repo: https://github.com/my-org/q4-data.git
    format: csv
  
  # Test dataset for model validation  
  - repo: https://github.com/my-org/test-set.git
    format: json
```

### Tip 3: Different Branches
```yaml
repositories:
  - repo: https://github.com/my-org/data.git
    branch: production  # Use production branch
```

### Tip 4: Remove When Done
Comment out or remove repos you've already processed:

```yaml
repositories:
  # Already processed - commenting out
  # - repo: https://github.com/my-org/old-data.git
  
  # New one to process
  - repo: https://github.com/my-org/new-data.git
```

---

## 🎬 Quick Demo

Try it right now with a test:

```bash
cd /Users/moon/Documents/pipeline

# Edit the file
cat >> repos-to-process.yaml << 'EOF'
repositories:
  - repo: https://github.com/almightymoon/Pipeline.git
    type: code
EOF

# Push
git add repos-to-process.yaml
git commit -m "Test auto-process workflow"
git push

# Watch
gh run watch
```

---

## 📚 Compare Methods

| Method | Complexity | Use Case |
|--------|-----------|----------|
| **Edit repos-to-process.yaml** | ⭐ Easy | Best for regular processing |
| Manual GitHub UI trigger | ⭐⭐ Medium | One-off dataset processing |
| Command line `gh workflow run` | ⭐⭐⭐ Advanced | Scripting & automation |

---

## ✅ Summary

**Old Way** (Manual):
1. Go to GitHub Actions
2. Click Run workflow
3. Fill in form with repo URL
4. Click Run workflow
5. Wait for completion

**New Way** (Automated):
1. Edit `repos-to-process.yaml`
2. Push

**3 steps simpler!** 🎉

---

**Questions?** Check:
- [HOW_TO_USE.md](HOW_TO_USE.md) - Detailed guide
- [QUICK_START.md](QUICK_START.md) - Quick reference
- [docs/DATASET_PROCESSING_GUIDE.md](docs/DATASET_PROCESSING_GUIDE.md) - Complete docs

