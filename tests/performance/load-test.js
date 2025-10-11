// K6 Load Test Script for ML Pipeline
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// Custom metrics
export let errorRate = new Rate('errors');
export let responseTime = new Trend('response_time');

// Test configuration
export let options = {
  stages: [
    { duration: '2m', target: 10 }, // Ramp up to 10 users
    { duration: '5m', target: 10 }, // Stay at 10 users
    { duration: '2m', target: 20 }, // Ramp up to 20 users
    { duration: '5m', target: 20 }, // Stay at 20 users
    { duration: '2m', target: 0 },  // Ramp down to 0 users
  ],
  thresholds: {
    http_req_duration: ['p(95)<2000'], // 95% of requests should be below 2s
    http_req_failed: ['rate<0.1'],     // Error rate should be below 10%
    errors: ['rate<0.1'],              // Custom error rate below 10%
  },
};

// Test data
const BASE_URL = __ENV.BASE_URL || 'https://ml-pipeline.yourcompany.com';
const API_ENDPOINTS = [
  '/api/v1/health',
  '/api/v1/status',
  '/api/v1/models',
  '/api/v1/predict',
  '/api/v1/metrics',
];

// Test scenarios
export function setup() {
  console.log('🚀 Starting ML Pipeline Load Test');
  console.log(`📊 Base URL: ${BASE_URL}`);
  
  // Health check before starting load test
  let healthResponse = http.get(`${BASE_URL}/api/v1/health`);
  if (healthResponse.status !== 200) {
    throw new Error(`Health check failed: ${healthResponse.status}`);
  }
  
  return { baseUrl: BASE_URL };
}

export default function(data) {
  // Random endpoint selection
  let endpoint = API_ENDPOINTS[Math.floor(Math.random() * API_ENDPOINTS.length)];
  let url = `${data.baseUrl}${endpoint}`;
  
  // Add random query parameters for cache busting
  let params = {
    headers: {
      'Content-Type': 'application/json',
      'User-Agent': 'K6-LoadTest/1.0',
    },
    timeout: '30s',
  };
  
  // Different request types based on endpoint
  let response;
  if (endpoint === '/api/v1/predict') {
    // POST request for prediction endpoint
    let payload = {
      model_id: 'distilbert-classification',
      text: generateRandomText(),
      confidence_threshold: 0.8,
    };
    
    response = http.post(url, JSON.stringify(payload), params);
  } else {
    // GET request for other endpoints
    response = http.get(url, params);
  }
  
  // Record metrics
  errorRate.add(response.status >= 400);
  responseTime.add(response.timings.duration);
  
  // Assertions
  check(response, {
    'status is 200': (r) => r.status === 200,
    'response time < 2s': (r) => r.timings.duration < 2000,
    'response has content': (r) => r.body.length > 0,
    'response is JSON': (r) => {
      try {
        JSON.parse(r.body);
        return true;
      } catch (e) {
        return false;
      }
    },
  });
  
  // Additional checks for specific endpoints
  if (endpoint === '/api/v1/health') {
    check(response, {
      'health endpoint returns healthy': (r) => {
        let body = JSON.parse(r.body);
        return body.status === 'healthy';
      },
    });
  }
  
  if (endpoint === '/api/v1/predict') {
    check(response, {
      'prediction has result': (r) => {
        let body = JSON.parse(r.body);
        return body.hasOwnProperty('prediction') && body.hasOwnProperty('confidence');
      },
      'confidence is valid': (r) => {
        let body = JSON.parse(r.body);
        return body.confidence >= 0 && body.confidence <= 1;
      },
    });
  }
  
  // Random sleep between requests (1-3 seconds)
  sleep(Math.random() * 2 + 1);
}

export function teardown(data) {
  console.log('✅ Load test completed');
  
  // Send results to monitoring system
  let results = {
    timestamp: new Date().toISOString(),
    base_url: data.baseUrl,
    test_type: 'load_test',
    metrics: {
      error_rate: errorRate.rate,
      avg_response_time: responseTime.avg,
      p95_response_time: responseTime.p95,
    },
  };
  
  // Send to Prometheus Pushgateway (if configured)
  if (__ENV.PROMETHEUS_PUSHGATEWAY_URL) {
    let prometheusMetrics = `# HELP k6_load_test_error_rate Error rate from K6 load test
# TYPE k6_load_test_error_rate gauge
k6_load_test_error_rate{test_type="load_test"} ${errorRate.rate}

# HELP k6_load_test_response_time_avg Average response time from K6 load test
# TYPE k6_load_test_response_time_avg gauge
k6_load_test_response_time_avg{test_type="load_test"} ${responseTime.avg}

# HELP k6_load_test_response_time_p95 95th percentile response time from K6 load test
# TYPE k6_load_test_response_time_p95 gauge
k6_load_test_response_time_p95{test_type="load_test"} ${responseTime.p95}
`;
    
    http.post(__ENV.PROMETHEUS_PUSHGATEWAY_URL + '/metrics/job/k6_load_test', prometheusMetrics, {
      headers: { 'Content-Type': 'text/plain' },
    });
  }
}

// Helper functions
function generateRandomText() {
  const texts = [
    'This is a positive review of the product. I love it!',
    'The service was terrible and I would not recommend it.',
    'Average experience, nothing special but not bad either.',
    'Excellent quality and fast delivery. Highly recommended!',
    'Poor customer service and slow response times.',
    'Good product but could be improved in some areas.',
    'Outstanding performance and great value for money.',
    'Disappointed with the quality and would not buy again.',
  ];
  
  return texts[Math.floor(Math.random() * texts.length)];
}

// Stress test scenario (optional)
export let stressOptions = {
  stages: [
    { duration: '2m', target: 50 },  // Ramp up to 50 users
    { duration: '5m', target: 50 },  // Stay at 50 users
    { duration: '2m', target: 100 }, // Ramp up to 100 users
    { duration: '5m', target: 100 }, // Stay at 100 users
    { duration: '2m', target: 0 },   // Ramp down to 0 users
  ],
  thresholds: {
    http_req_duration: ['p(95)<5000'], // More lenient for stress test
    http_req_failed: ['rate<0.2'],     // Allow higher error rate
  },
};
