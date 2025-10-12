#!/usr/bin/env python3
"""
Dataset Processing Script
Transforms and cleans datasets for ML training
"""

import json
import sys
from pathlib import Path
import pandas as pd
import numpy as np
from typing import Dict, List, Any
import argparse


def process_csv_dataset(input_dir: Path, output_dir: Path, config: Dict) -> None:
    """Process CSV dataset files"""
    csv_files = list(input_dir.rglob('*.csv'))
    
    if not csv_files:
        print("No CSV files found")
        return
    
    print(f"📊 Processing {len(csv_files)} CSV files...")
    
    all_dataframes = []
    
    for file in csv_files:
        print(f"  Processing {file.name}...")
        df = pd.read_csv(file)
        
        # Apply transformations
        if config.get('remove_nulls', True):
            df = df.dropna()
        
        if config.get('remove_duplicates', True):
            df = df.drop_duplicates()
        
        if config.get('normalize', False):
            # Normalize numeric columns
            numeric_cols = df.select_dtypes(include=[np.number]).columns
            df[numeric_cols] = (df[numeric_cols] - df[numeric_cols].mean()) / df[numeric_cols].std()
        
        all_dataframes.append(df)
    
    # Combine all dataframes
    if all_dataframes:
        combined = pd.concat(all_dataframes, ignore_index=True)
        
        # Save in multiple formats
        output_dir.mkdir(parents=True, exist_ok=True)
        combined.to_csv(output_dir / 'processed.csv', index=False)
        combined.to_json(output_dir / 'processed.json', orient='records', indent=2)
        combined.to_parquet(output_dir / 'processed.parquet', index=False)
        
        print(f"✅ Saved processed dataset: {len(combined)} rows, {len(combined.columns)} columns")
        
        # Generate statistics
        stats = {
            "total_rows": len(combined),
            "total_columns": len(combined.columns),
            "columns": list(combined.columns),
            "dtypes": {col: str(dtype) for col, dtype in combined.dtypes.items()},
            "null_counts": combined.isnull().sum().to_dict(),
            "summary_statistics": combined.describe().to_dict()
        }
        
        with open(output_dir / 'statistics.json', 'w') as f:
            json.dump(stats, f, indent=2)


def process_json_dataset(input_dir: Path, output_dir: Path, config: Dict) -> None:
    """Process JSON dataset files"""
    json_files = list(input_dir.rglob('*.json'))
    
    if not json_files:
        print("No JSON files found")
        return
    
    print(f"📊 Processing {len(json_files)} JSON files...")
    
    all_data = []
    
    for file in json_files:
        print(f"  Processing {file.name}...")
        with open(file, 'r') as f:
            data = json.load(f)
        
        if isinstance(data, list):
            all_data.extend(data)
        else:
            all_data.append(data)
    
    if all_data:
        # Remove duplicates
        if config.get('remove_duplicates', True):
            all_data = [dict(t) for t in {tuple(d.items()) for d in all_data if isinstance(d, dict)}]
        
        # Save processed data
        output_dir.mkdir(parents=True, exist_ok=True)
        
        with open(output_dir / 'processed.json', 'w') as f:
            json.dump(all_data, f, indent=2)
        
        # Also save as CSV if possible
        try:
            df = pd.DataFrame(all_data)
            df.to_csv(output_dir / 'processed.csv', index=False)
            df.to_parquet(output_dir / 'processed.parquet', index=False)
        except Exception as e:
            print(f"Could not convert to CSV/Parquet: {e}")
        
        print(f"✅ Saved processed dataset: {len(all_data)} records")


def main():
    """Main processing function"""
    parser = argparse.ArgumentParser(description='Process datasets for ML training')
    parser.add_argument('--input', default='dataset', help='Input directory')
    parser.add_argument('--output', default='processed-dataset', help='Output directory')
    parser.add_argument('--format', default='auto', choices=['auto', 'csv', 'json', 'parquet'])
    parser.add_argument('--no-remove-nulls', action='store_true', help='Keep null values')
    parser.add_argument('--no-remove-duplicates', action='store_true', help='Keep duplicates')
    parser.add_argument('--normalize', action='store_true', help='Normalize numeric columns')
    
    args = parser.parse_args()
    
    input_dir = Path(args.input)
    output_dir = Path(args.output)
    
    if not input_dir.exists():
        print(f"❌ Input directory not found: {input_dir}")
        sys.exit(1)
    
    config = {
        'remove_nulls': not args.no_remove_nulls,
        'remove_duplicates': not args.no_remove_duplicates,
        'normalize': args.normalize
    }
    
    print("=" * 60)
    print("🔄 Dataset Processing Starting...")
    print("=" * 60)
    print(f"\nInput: {input_dir}")
    print(f"Output: {output_dir}")
    print(f"Configuration: {config}")
    print()
    
    # Process based on format
    if args.format == 'csv' or (args.format == 'auto' and list(input_dir.rglob('*.csv'))):
        process_csv_dataset(input_dir, output_dir, config)
    
    if args.format == 'json' or (args.format == 'auto' and list(input_dir.rglob('*.json'))):
        process_json_dataset(input_dir, output_dir, config)
    
    print("\n" + "=" * 60)
    print("✅ Dataset Processing Complete!")
    print("=" * 60)


if __name__ == '__main__':
    main()

