#!/usr/bin/env python3
"""
Dataset Validation Script
Validates dataset structure and quality
"""

import json
import sys
from pathlib import Path
import pandas as pd
from typing import Dict, List, Any


def validate_csv_dataset(file_path: Path) -> Dict[str, Any]:
    """Validate a CSV dataset file"""
    try:
        df = pd.read_csv(file_path)
        
        validation = {
            "file": str(file_path),
            "rows": len(df),
            "columns": len(df.columns),
            "column_names": list(df.columns),
            "null_count": df.isnull().sum().sum(),
            "duplicate_count": df.duplicated().sum(),
            "memory_usage_mb": df.memory_usage(deep=True).sum() / (1024 * 1024),
            "valid": True
        }
        
        # Check for issues
        if validation["null_count"] > 0:
            print(f"Warning: {validation['null_count']} null values found in {file_path.name}")
        
        if validation["duplicate_count"] > 0:
            print(f"Warning: {validation['duplicate_count']} duplicate rows found in {file_path.name}")
        
        return validation
        
    except Exception as e:
        return {
            "file": str(file_path),
            "valid": False,
            "error": str(e)
        }


def validate_json_dataset(file_path: Path) -> Dict[str, Any]:
    """Validate a JSON dataset file"""
    try:
        with open(file_path, 'r') as f:
            data = json.load(f)
        
        if isinstance(data, list):
            record_count = len(data)
            sample = data[0] if data else {}
        else:
            record_count = 1
            sample = data
        
        validation = {
            "file": str(file_path),
            "records": record_count,
            "sample_keys": list(sample.keys()) if isinstance(sample, dict) else [],
            "file_size_mb": file_path.stat().st_size / (1024 * 1024),
            "valid": True
        }
        
        return validation
        
    except Exception as e:
        return {
            "file": str(file_path),
            "valid": False,
            "error": str(e)
        }


def main():
    """Main validation function"""
    print("=" * 60)
    print("🔍 Dataset Validation Starting...")
    print("=" * 60)
    
    dataset_dir = Path('dataset') if Path('dataset').exists() else Path('.')
    
    # Find dataset files
    csv_files = list(dataset_dir.rglob('*.csv'))
    json_files = list(dataset_dir.rglob('*.json'))
    parquet_files = list(dataset_dir.rglob('*.parquet'))
    
    print(f"\nFound:")
    print(f"  - {len(csv_files)} CSV files")
    print(f"  - {len(json_files)} JSON files")
    print(f"  - {len(parquet_files)} Parquet files")
    
    results = []
    errors = []
    
    # Validate CSV files
    for file in csv_files:
        result = validate_csv_dataset(file)
        results.append(result)
        if not result.get('valid', False):
            errors.append(result)
    
    # Validate JSON files
    for file in json_files:
        result = validate_json_dataset(file)
        results.append(result)
        if not result.get('valid', False):
            errors.append(result)
    
    # Summary
    print(f"\n{'=' * 60}")
    print(f"Validation Summary:")
    print(f"{'=' * 60}")
    print(f"Total files validated: {len(results)}")
    print(f"Valid files: {len([r for r in results if r.get('valid', False)])}")
    print(f"Invalid files: {len(errors)}")
    
    if errors:
        print(f"\nErrors found:")
        for error in errors:
            print(f"  - {error['file']}: {error.get('error', 'Unknown error')}")
        sys.exit(1)
    else:
        print(f"\nAll datasets are valid!")
    
    # Save results
    with open('validation-results.json', 'w') as f:
        json.dump(results, f, indent=2)


if __name__ == '__main__':
    main()

