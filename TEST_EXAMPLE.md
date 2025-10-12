# 🧪 Test Example - Try This Now!

## Step 1: Edit repos-to-process.yaml

Replace the example with your actual dataset:

```yaml
repositories:
  # Your dataset:
  - repo: https://github.com/YOUR-USERNAME/YOUR-DATASET.git
    branch: main
    format: json  # or csv, or parquet
```

## Step 2: Commit and Push

```bash
git add repos-to-process.yaml
git commit -m "Process my dataset"
git push
```

## Step 3: Watch It Run

```bash
# Method A: Watch in terminal
gh run watch

# Method B: Open in browser
open https://github.com/almightymoon/Pipeline/actions
```

## Step 4: Get Results

After ~2-3 minutes:

```bash
# Download all artifacts
gh run download

# Or check Kubernetes
ssh ubuntu@213.109.162.134
kubectl get configmaps -n ml-pipeline -l app=dataset-processor
```

---

## 🎉 That's It!

Your dataset is now:
- ✅ Validated
- ✅ Cleaned
- ✅ Processed
- ✅ Ready to use!

**Try it with your actual dataset now!** 🚀
