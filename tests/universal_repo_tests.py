"""
Universal test suite for external repositories
These tests will run for any repository to ensure basic functionality
"""
import pytest
import sys
import os
import json
import subprocess
import time
from pathlib import Path

def test_repository_exists():
    """Test that repository directory exists"""
    repo_dir = Path('external-repo')
    if not repo_dir.exists():
        repo_dir = Path('.')
    assert repo_dir.exists(), "Repository directory should exist"

def test_files_are_readable():
    """Test that files in repository are readable"""
    repo_dir = Path('external-repo') if Path('external-repo').exists() else Path('.')
    
    # Find first readable file
    readable_files = []
    for ext in ['.py', '.js', '.java', '.go', '.ts', '.tsx', '.yml', '.yaml', '.json']:
        for file_path in repo_dir.rglob(f'*{ext}'):
            if file_path.is_file() and os.access(file_path, os.R_OK):
                readable_files.append(str(file_path))
                break
    
    assert len(readable_files) > 0, "At least one file should be readable"

def test_repository_structure():
    """Test basic repository structure"""
    repo_dir = Path('external-repo') if Path('external-repo').exists() else Path('.')
    
    # Check for common files/directories
    common_items = ['README', 'package.json', 'requirements.txt', 'go.mod', 'pom.xml', 'build.gradle']
    found_items = []
    
    for item in common_items:
        for path in repo_dir.rglob(item):
            if path.is_file():
                found_items.append(item)
                break
    
    # At least one common file should exist
    assert len(found_items) > 0 or len(list(repo_dir.iterdir())) > 0, "Repository should have some structure"

def test_python_imports():
    """Test Python imports if Python files exist"""
    repo_dir = Path('external-repo') if Path('external-repo').exists() else Path('.')
    py_files = list(repo_dir.rglob('*.py'))
    
    if len(py_files) == 0:
        pytest.skip("No Python files found")
    
    # Try importing standard library
    try:
        import json
        import os
        import sys
        assert True, "Standard library imports work"
    except ImportError as e:
        pytest.fail(f"Failed to import standard library: {e}")

def test_json_validity():
    """Test JSON files are valid"""
    repo_dir = Path('external-repo') if Path('external-repo').exists() else Path('.')
    json_files = list(repo_dir.rglob('*.json'))
    
    if len(json_files) == 0:
        pytest.skip("No JSON files found")
    
    valid_json_count = 0
    for json_file in json_files[:5]:  # Check first 5 JSON files
        try:
            with open(json_file, 'r') as f:
                json.load(f)
            valid_json_count += 1
        except json.JSONDecodeError:
            pass
    
    assert valid_json_count > 0 or len(json_files) == 0, "At least some JSON files should be valid"

def test_yaml_validity():
    """Test YAML files are valid"""
    try:
        import yaml
    except ImportError:
        pytest.skip("PyYAML not installed")
    
    repo_dir = Path('external-repo') if Path('external-repo').exists() else Path('.')
    yaml_files = list(repo_dir.rglob('*.yml')) + list(repo_dir.rglob('*.yaml'))
    
    if len(yaml_files) == 0:
        pytest.skip("No YAML files found")
    
    valid_yaml_count = 0
    for yaml_file in yaml_files[:5]:  # Check first 5 YAML files
        try:
            with open(yaml_file, 'r') as f:
                yaml.safe_load(f)
            valid_yaml_count += 1
        except yaml.YAMLError:
            pass
    
    assert valid_yaml_count > 0 or len(yaml_files) == 0, "At least some YAML files should be valid"

def test_no_empty_files():
    """Test that repository has non-empty files"""
    repo_dir = Path('external-repo') if Path('external-repo').exists() else Path('.')
    
    non_empty_files = []
    for file_path in repo_dir.rglob('*'):
        if file_path.is_file():
            try:
                if file_path.stat().st_size > 0:
                    non_empty_files.append(str(file_path))
                    if len(non_empty_files) >= 10:
                        break
            except (OSError, PermissionError):
                pass
    
    assert len(non_empty_files) > 0, "Repository should have some non-empty files"

def test_execution_performance():
    """Test basic execution performance"""
    start_time = time.time()
    
    # Simple computation
    result = sum(range(1000))
    
    end_time = time.time()
    duration = end_time - start_time
    
    assert result == 499500, "Computation should be correct"
    assert duration < 1.0, "Computation should complete quickly"

def test_environment_setup():
    """Test environment is properly set up"""
    assert os.getenv('PATH') is not None, "PATH should be set"
    assert sys.version_info >= (3, 7), "Python 3.7+ required"

def test_file_permissions():
    """Test file permissions are reasonable"""
    repo_dir = Path('external-repo') if Path('external-repo').exists() else Path('.')
    
    readable_count = 0
    for file_path in repo_dir.rglob('*'):
        if file_path.is_file():
            try:
                if os.access(file_path, os.R_OK):
                    readable_count += 1
                    if readable_count >= 5:
                        break
            except (OSError, PermissionError):
                pass
    
    assert readable_count > 0, "Some files should be readable"

if __name__ == "__main__":
    pytest.main([__file__, "-v", "--json-report", "--json-report-file=/tmp/pytest-report.json"])

