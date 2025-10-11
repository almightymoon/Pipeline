"""
Integration tests for ML Pipeline API endpoints
"""
import pytest
import requests
import json
import time
import os
from typing import Dict, Any


class TestMLPipelineIntegration:
    """Integration test suite for ML Pipeline API"""
    
    @pytest.fixture(autouse=True)
    def setup(self):
        """Setup test environment"""
        self.base_url = os.getenv('API_BASE_URL', 'https://ml-pipeline.yourcompany.com')
        self.api_version = 'v1'
        self.headers = {
            'Content-Type': 'application/json',
            'User-Agent': 'ML-Pipeline-Integration-Test/1.0'
        }
        self.timeout = 30
        
        # Wait for service to be ready
        self.wait_for_service()
    
    def wait_for_service(self, max_attempts: int = 30, delay: int = 2):
        """Wait for the service to be ready"""
        for attempt in range(max_attempts):
            try:
                response = requests.get(
                    f"{self.base_url}/api/{self.api_version}/health",
                    headers=self.headers,
                    timeout=10
                )
                if response.status_code == 200:
                    print(f"✅ Service is ready after {attempt + 1} attempts")
                    return
            except requests.exceptions.RequestException:
                pass
            
            print(f"⏳ Waiting for service... attempt {attempt + 1}/{max_attempts}")
            time.sleep(delay)
        
        raise Exception("❌ Service did not become ready within timeout")
    
    def test_health_endpoint(self):
        """Test health check endpoint"""
        response = requests.get(
            f"{self.base_url}/api/{self.api_version}/health",
            headers=self.headers,
            timeout=self.timeout
        )
        
        assert response.status_code == 200
        data = response.json()
        assert 'status' in data
        assert data['status'] == 'healthy'
        assert 'timestamp' in data
        assert 'uptime' in data
    
    def test_status_endpoint(self):
        """Test status endpoint"""
        response = requests.get(
            f"{self.base_url}/api/{self.api_version}/status",
            headers=self.headers,
            timeout=self.timeout
        )
        
        assert response.status_code == 200
        data = response.json()
        assert 'status' in data
        assert 'uptime' in data
        assert 'version' in data
        assert 'environment' in data
        assert 'git_commit' in data
    
    def test_models_endpoint(self):
        """Test models listing endpoint"""
        response = requests.get(
            f"{self.base_url}/api/{self.api_version}/models",
            headers=self.headers,
            timeout=self.timeout
        )
        
        assert response.status_code == 200
        data = response.json()
        assert 'models' in data
        assert isinstance(data['models'], list)
        assert len(data['models']) > 0
        
        # Check model structure
        model = data['models'][0]
        assert 'id' in model
        assert 'name' in model
        assert 'version' in model
        assert 'status' in model
    
    def test_prediction_endpoint_success(self):
        """Test prediction endpoint with valid data"""
        test_data = {
            "model_id": "distilbert-classification",
            "text": "This is a great product!",
            "confidence_threshold": 0.8
        }
        
        response = requests.post(
            f"{self.base_url}/api/{self.api_version}/predict",
            headers=self.headers,
            json=test_data,
            timeout=self.timeout
        )
        
        assert response.status_code == 200
        data = response.json()
        assert 'prediction' in data
        assert 'confidence' in data
        assert 'model_id' in data
        assert 'processing_time' in data
        
        # Validate prediction format
        assert isinstance(data['prediction'], (str, int, float))
        assert 0 <= data['confidence'] <= 1
    
    def test_prediction_endpoint_invalid_model(self):
        """Test prediction endpoint with invalid model ID"""
        test_data = {
            "model_id": "nonexistent-model",
            "text": "Test text",
            "confidence_threshold": 0.8
        }
        
        response = requests.post(
            f"{self.base_url}/api/{self.api_version}/predict",
            headers=self.headers,
            json=test_data,
            timeout=self.timeout
        )
        
        assert response.status_code == 400
        data = response.json()
        assert 'error' in data
        assert 'message' in data
    
    def test_prediction_endpoint_missing_fields(self):
        """Test prediction endpoint with missing required fields"""
        test_data = {
            "text": "Test text"
            # Missing model_id and confidence_threshold
        }
        
        response = requests.post(
            f"{self.base_url}/api/{self.api_version}/predict",
            headers=self.headers,
            json=test_data,
            timeout=self.timeout
        )
        
        assert response.status_code == 400
        data = response.json()
        assert 'error' in data
    
    def test_prediction_endpoint_large_text(self):
        """Test prediction endpoint with large text input"""
        large_text = "This is a test. " * 1000  # Large text
        
        test_data = {
            "model_id": "distilbert-classification",
            "text": large_text,
            "confidence_threshold": 0.8
        }
        
        response = requests.post(
            f"{self.base_url}/api/{self.api_version}/predict",
            headers=self.headers,
            json=test_data,
            timeout=self.timeout
        )
        
        # Should handle large text gracefully
        assert response.status_code in [200, 413]  # 413 = Payload Too Large
    
    def test_metrics_endpoint(self):
        """Test metrics endpoint"""
        response = requests.get(
            f"{self.base_url}/api/{self.api_version}/metrics",
            headers=self.headers,
            timeout=self.timeout
        )
        
        assert response.status_code == 200
        data = response.json()
        assert 'predictions_total' in data
        assert 'predictions_success' in data
        assert 'predictions_failed' in data
        assert 'average_processing_time' in data
        assert 'uptime_seconds' in data
    
    def test_cors_headers(self):
        """Test CORS headers are present"""
        response = requests.options(
            f"{self.base_url}/api/{self.api_version}/health",
            headers={
                **self.headers,
                'Origin': 'https://example.com',
                'Access-Control-Request-Method': 'GET'
            },
            timeout=self.timeout
        )
        
        assert 'Access-Control-Allow-Origin' in response.headers
        assert 'Access-Control-Allow-Methods' in response.headers
    
    def test_rate_limiting(self):
        """Test rate limiting functionality"""
        # Send multiple requests quickly
        responses = []
        for i in range(10):
            response = requests.get(
                f"{self.base_url}/api/{self.api_version}/health",
                headers=self.headers,
                timeout=self.timeout
            )
            responses.append(response)
            time.sleep(0.1)  # Small delay between requests
        
        # All requests should succeed (rate limiting should be generous for health checks)
        success_count = sum(1 for r in responses if r.status_code == 200)
        assert success_count >= 8  # Allow some flexibility
    
    def test_concurrent_requests(self):
        """Test concurrent request handling"""
        import concurrent.futures
        import threading
        
        def make_request():
            response = requests.get(
                f"{self.base_url}/api/{self.api_version}/health",
                headers=self.headers,
                timeout=self.timeout
            )
            return response.status_code
        
        # Make 5 concurrent requests
        with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
            futures = [executor.submit(make_request) for _ in range(5)]
            results = [future.result() for future in concurrent.futures.as_completed(futures)]
        
        # All requests should succeed
        assert all(status == 200 for status in results)
    
    def test_error_handling(self):
        """Test error handling for various scenarios"""
        # Test 404 endpoint
        response = requests.get(
            f"{self.base_url}/api/{self.api_version}/nonexistent",
            headers=self.headers,
            timeout=self.timeout
        )
        assert response.status_code == 404
        
        # Test invalid JSON
        response = requests.post(
            f"{self.base_url}/api/{self.api_version}/predict",
            headers=self.headers,
            data="invalid json",
            timeout=self.timeout
        )
        assert response.status_code == 400
    
    def test_model_loading_and_caching(self):
        """Test that models are loaded and cached properly"""
        # First request - should load model
        start_time = time.time()
        test_data = {
            "model_id": "distilbert-classification",
            "text": "First request",
            "confidence_threshold": 0.8
        }
        
        response1 = requests.post(
            f"{self.base_url}/api/{self.api_version}/predict",
            headers=self.headers,
            json=test_data,
            timeout=self.timeout
        )
        
        first_request_time = time.time() - start_time
        
        # Second request - should use cached model
        start_time = time.time()
        test_data["text"] = "Second request"
        
        response2 = requests.post(
            f"{self.base_url}/api/{self.api_version}/predict",
            headers=self.headers,
            json=test_data,
            timeout=self.timeout
        )
        
        second_request_time = time.time() - start_time
        
        # Both requests should succeed
        assert response1.status_code == 200
        assert response2.status_code == 200
        
        # Second request should be faster (cached model)
        assert second_request_time < first_request_time


class TestMLPipelineEndToEnd:
    """End-to-end integration tests"""
    
    @pytest.fixture(autouse=True)
    def setup(self):
        """Setup test environment"""
        self.base_url = os.getenv('API_BASE_URL', 'https://ml-pipeline.yourcompany.com')
        self.api_version = 'v1'
        self.headers = {
            'Content-Type': 'application/json',
            'User-Agent': 'ML-Pipeline-E2E-Test/1.0'
        }
        self.timeout = 30
    
    def test_complete_prediction_workflow(self):
        """Test complete prediction workflow"""
        # 1. Check health
        health_response = requests.get(
            f"{self.base_url}/api/{self.api_version}/health",
            headers=self.headers,
            timeout=self.timeout
        )
        assert health_response.status_code == 200
        
        # 2. Get available models
        models_response = requests.get(
            f"{self.base_url}/api/{self.api_version}/models",
            headers=self.headers,
            timeout=self.timeout
        )
        assert models_response.status_code == 200
        models = models_response.json()['models']
        assert len(models) > 0
        
        # 3. Make prediction
        model_id = models[0]['id']
        test_data = {
            "model_id": model_id,
            "text": "This is an excellent product with great quality!",
            "confidence_threshold": 0.8
        }
        
        prediction_response = requests.post(
            f"{self.base_url}/api/{self.api_version}/predict",
            headers=self.headers,
            json=test_data,
            timeout=self.timeout
        )
        assert prediction_response.status_code == 200
        
        # 4. Check metrics
        metrics_response = requests.get(
            f"{self.base_url}/api/{self.api_version}/metrics",
            headers=self.headers,
            timeout=self.timeout
        )
        assert metrics_response.status_code == 200
        
        # 5. Verify metrics updated
        metrics = metrics_response.json()
        assert metrics['predictions_total'] > 0
        assert metrics['predictions_success'] > 0
    
    def test_error_recovery_workflow(self):
        """Test error recovery workflow"""
        # 1. Make invalid request
        invalid_data = {
            "model_id": "invalid-model",
            "text": "Test text",
            "confidence_threshold": 0.8
        }
        
        error_response = requests.post(
            f"{self.base_url}/api/{self.api_version}/predict",
            headers=self.headers,
            json=invalid_data,
            timeout=self.timeout
        )
        assert error_response.status_code == 400
        
        # 2. Make valid request after error
        valid_data = {
            "model_id": "distilbert-classification",
            "text": "Test text",
            "confidence_threshold": 0.8
        }
        
        success_response = requests.post(
            f"{self.base_url}/api/{self.api_version}/predict",
            headers=self.headers,
            json=valid_data,
            timeout=self.timeout
        )
        assert success_response.status_code == 200
        
        # 3. Verify error was recorded in metrics
        metrics_response = requests.get(
            f"{self.base_url}/api/{self.api_version}/metrics",
            headers=self.headers,
            timeout=self.timeout
        )
        assert metrics_response.status_code == 200
        
        metrics = metrics_response.json()
        assert metrics['predictions_failed'] > 0


if __name__ == '__main__':
    pytest.main([__file__, '-v', '--tb=short'])
