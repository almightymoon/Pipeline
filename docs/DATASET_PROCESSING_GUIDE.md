# 📊 Dataset Processing with Your Pipeline

## 🎯 Quick Start - Process Any Dataset

You can process datasets from any GitHub repository through your pipeline in just a few steps!

---

## 🚀 Method 1: Run Manually (Easiest)

### Step 1: Trigger the Workflow

Go to your pipeline repository on GitHub:
```
https://github.com/your-org/pipeline/actions/workflows/dataset-pipeline.yml
```

Click **"Run workflow"** and enter:
- **Dataset Repository URL**: `https://github.com/your-org/your-dataset.git`
- **Branch**: `main` (or your dataset branch)
- **Format**: `json` (or `csv`, `parquet`)

Click **"Run workflow"** - Done! ✅

### Step 2: Monitor Progress

The pipeline will:
1. ✅ Clone your dataset repository
2. ✅ Validate the data structure
3. ✅ Process and clean the data
4. ✅ Deploy to Kubernetes
5. ✅ Generate reports

### Step 3: Get Results

Download the processed dataset from:
- **GitHub Actions** → Your workflow run → **Artifacts** → `processed-dataset`

---

## 🖥️ Method 2: Use Command Line

```bash
# Trigger the dataset pipeline
gh workflow run dataset-pipeline.yml \
  -f dataset_repo="https://github.com/your-org/your-dataset.git" \
  -f dataset_branch="main" \
  -f dataset_format="json"

# Wait a moment, then watch progress
gh run watch

# Download results
gh run download <run-id>
```

---

## 📁 Method 3: Add to Your Dataset Repo

### Copy the workflow to your dataset repository:

```bash
cd /path/to/your-dataset-repo

# Create workflow directory
mkdir -p .github/workflows

# Create a simple processing workflow
cat > .github/workflows/process-dataset.yml << 'EOF'
name: 📊 Process Dataset

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  process:
    runs-on: ubuntu-latest
    
    steps:
    - name: 📥 Checkout Dataset
      uses: actions/checkout@v4
    
    - name: 🐍 Setup Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.11'
    
    - name: 📦 Install Tools
      run: |
        pip install pandas numpy jsonschema
    
    - name: 🔄 Process Dataset
      run: |
        python << 'SCRIPT'
        import pandas as pd
        import json
        from pathlib import Path
        
        # Find all data files
        data_files = list(Path('.').rglob('*.csv')) + list(Path('.').rglob('*.json'))
        
        print(f"Found {len(data_files)} data files")
        
        for file in data_files:
            print(f"Processing: {file}")
            if file.suffix == '.csv':
                df = pd.read_csv(file)
                print(f"  - {len(df)} rows, {len(df.columns)} columns")
            elif file.suffix == '.json':
                with open(file) as f:
                    data = json.load(f)
                print(f"  - {len(data) if isinstance(data, list) else 1} records")
        
        print("✅ Processing complete!")
        SCRIPT
    
    - name: 📤 Upload Results
      uses: actions/upload-artifact@v4
      with:
        name: processed-data
        path: processed/
EOF

# Commit and push
git add .github/workflows/process-dataset.yml
git commit -m "Add dataset processing pipeline"
git push
```

Now every time you push to your dataset repo, it will automatically process!

---

## 🎯 Method 4: Use as Remote Workflow

### In Your Dataset Repository

Create `.github/workflows/use-remote-pipeline.yml`:

```yaml
name: 📊 Use Remote Pipeline

on:
  push:
    branches: [ main ]

jobs:
  trigger-remote-pipeline:
    runs-on: ubuntu-latest
    
    steps:
    - name: 🔗 Trigger Main Pipeline
      uses: peter-evans/repository-dispatch@v2
      with:
        token: ${{ secrets.PIPELINE_TRIGGER_TOKEN }}
        repository: your-org/pipeline
        event-type: process-external-dataset
        client-payload: |
          {
            "repo_url": "${{ github.repository }}",
            "repo_branch": "${{ github.ref_name }}",
            "dataset_format": "json"
          }
```

---

## 💡 Example: Process a Hugging Face Dataset

```bash
# Clone a dataset from Hugging Face
git clone https://huggingface.co/datasets/squad dataset-squad
cd dataset-squad

# Trigger your pipeline
gh workflow run dataset-pipeline.yml \
  -R your-org/pipeline \
  -f dataset_repo="https://huggingface.co/datasets/squad" \
  -f dataset_format="json"
```

---

## 🔧 Configuration Options

### Dataset Formats Supported

| Format | Extensions | Processing |
|--------|-----------|------------|
| **CSV** | `.csv` | Pandas DataFrame processing |
| **JSON** | `.json` | Schema validation + transformation |
| **Parquet** | `.parquet` | Efficient columnar processing |

### Processing Options

The pipeline can:
- ✅ Remove null values
- ✅ Remove duplicates
- ✅ Normalize numeric columns
- ✅ Validate schema
- ✅ Generate statistics
- ✅ Split train/test/val
- ✅ Convert between formats

### Custom Processing

Add a `dataset-config.yaml` to your dataset repo:

```yaml
processing:
  remove_nulls: true
  remove_duplicates: true
  normalize: true
  
validation:
  schema_file: "schema.json"
  required_columns:
    - id
    - text
    - label
  
output:
  formats:
    - csv
    - json
    - parquet
  split:
    train: 0.8
    test: 0.1
    val: 0.1
```

---

## 🎓 Complete Example

### Your Dataset Repository Structure

```
my-dataset/
├── .github/workflows/
│   └── process.yml              # Processing workflow
├── data/
│   ├── raw/
│   │   ├── data1.csv
│   │   ├── data2.csv
│   │   └── data3.json
│   └── processed/               # Output goes here
├── scripts/
│   ├── validate.py
│   └── transform.py
├── dataset-config.yaml          # Processing configuration
├── schema.json                  # Data schema
└── README.md
```

### Run Processing

```bash
# Local testing
python scripts/validate.py
python scripts/transform.py

# Or trigger via GitHub Actions
git push origin main
```

### Access Processed Data

1. **From GitHub Actions**:
   - Go to Actions → Latest run → Artifacts → Download `processed-dataset`

2. **From Kubernetes**:
   ```bash
   # List datasets in cluster
   kubectl get configmaps -n ml-pipeline -l app=dataset-processor
   
   # Get specific dataset
   kubectl get configmap processed-dataset-20251012 -n ml-pipeline -o yaml
   ```

3. **From Grafana**:
   - View dataset processing metrics
   - Track processing times
   - Monitor data quality trends

---

## 📊 Real-World Example: Twitter Sentiment Dataset

Let's say you have a Twitter sentiment dataset:

### 1. Prepare Your Dataset Repo

```bash
git clone https://github.com/your-org/twitter-sentiment-dataset.git
cd twitter-sentiment-dataset

# Your data structure:
# data/
#   tweets_2024_01.csv
#   tweets_2024_02.csv
#   tweets_2024_03.csv
```

### 2. Add Processing Workflow

```bash
mkdir -p .github/workflows
cp /path/to/pipeline/.github/workflows/dataset-pipeline.yml .github/workflows/
```

### 3. Customize for Your Data

```yaml
# .github/workflows/process-tweets.yml
- name: 🔄 Process Tweets
  run: |
    python << 'EOF'
    import pandas as pd
    from pathlib import Path
    
    # Load all tweet files
    tweet_files = list(Path('data').glob('tweets_*.csv'))
    dfs = [pd.read_csv(f) for f in tweet_files]
    all_tweets = pd.concat(dfs, ignore_index=True)
    
    # Clean the data
    all_tweets = all_tweets.dropna(subset=['text', 'sentiment'])
    all_tweets = all_tweets.drop_duplicates(subset=['text'])
    
    # Process text
    all_tweets['text'] = all_tweets['text'].str.lower()
    all_tweets['text'] = all_tweets['text'].str.strip()
    
    # Save processed
    all_tweets.to_json('processed/tweets_processed.json', orient='records', lines=True)
    
    print(f"✅ Processed {len(all_tweets)} tweets")
    EOF
```

### 4. Push and Run

```bash
git add .
git commit -m "Add dataset processing pipeline"
git push
```

### 5. Results

- **Processed JSON**: Download from GitHub Actions artifacts
- **Kubernetes ConfigMap**: Available in your cluster for training jobs
- **Metrics**: View in Grafana dashboard

---

## 🔍 Monitoring Your Dataset Processing

### Grafana Dashboard

Your pipeline automatically sends metrics:

```
dataset_processed_total{format="json"} 1
dataset_rows_processed{repo="twitter-sentiment"} 150000
dataset_processing_time_seconds{repo="twitter-sentiment"} 45
dataset_quality_score{repo="twitter-sentiment"} 0.95
```

### Jira Integration

If configured, creates Jira issues for:
- ❌ Dataset validation failures
- ⚠️  Data quality issues
- ✅ Processing completion (optional)

---

## 🆘 Troubleshooting

### Issue: "No data files found"

**Solution**: Ensure your data is in the repository and matches the expected extensions (`.csv`, `.json`, `.parquet`)

### Issue: "Schema validation failed"

**Solution**: Check your data matches the expected schema or update the schema file

### Issue: "Processing takes too long"

**Solution**: 
- Process in batches
- Use larger GitHub Actions runners
- Deploy processing to Kubernetes for large datasets

---

## 💡 Tips & Best Practices

### 1. Version Your Datasets

```bash
git tag v1.0-dataset-20251012
git push --tags
```

### 2. Use Git LFS for Large Files

```bash
git lfs install
git lfs track "*.csv"
git lfs track "*.parquet"
git add .gitattributes
```

### 3. Automate Quality Checks

Add validation rules to your workflow to ensure data quality.

### 4. Cache Processed Data

Use GitHub Actions cache to avoid reprocessing:

```yaml
- uses: actions/cache@v3
  with:
    path: processed-dataset/
    key: dataset-${{ hashFiles('data/**') }}
```

---

## 🎉 You're Ready!

Now you can:
- ✅ Process any dataset through your pipeline
- ✅ Automate data validation and transformation
- ✅ Deploy processed data to Kubernetes
- ✅ Monitor data quality with Grafana
- ✅ Track issues with Jira

**Happy Data Processing!** 🚀

