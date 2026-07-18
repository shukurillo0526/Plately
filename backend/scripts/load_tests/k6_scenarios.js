import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 200 }, // Ramp up to 200 users over 30 seconds
    { duration: '1m', target: 200 },  // Stay at 200 users for 1 minute
    { duration: '30s', target: 0 },  // Ramp down to 0 users
  ],
  thresholds: {
    http_req_duration: ['p(95)<2000'], // 95% of requests must complete below 2000ms under extreme load
    http_req_failed: ['rate<0.05'],   // Error rate must be less than 5%
  },
};

const BASE_URL = 'http://localhost:8000';

// Mock test data
const DUMMY_USER_ID = '00000000-0000-0000-0000-000000000000';
const REAL_TOKEN = 'eyJhbGciOiJFUzI1NiIsImtpZCI6IjBkYjg2YjU3LTAxNDktNDMwZS04ZjIyLTQwZTI3OTQzY2IwNCIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJodHRwczovL3RxdXlvZHdzeXBwd2JwdmthdW5uLnN1cGFiYXNlLmNvL2F1dGgvdjEiLCJzdWIiOiJkODg2MjUyMy0yNTUwLTQ4YmEtOWUyNC01MGU4NmE2ZTRlYTkiLCJhdWQiOiJhdXRoZW50aWNhdGVkIiwiZXhwIjoxNzg0Mzg4MTY5LCJpYXQiOjE3ODQzODQ1NjksImVtYWlsIjoibG9hZEB0ZXN0LmNvbSIsInBob25lIjoiIiwiYXBwX21ldGFkYXRhIjp7InByb3ZpZGVyIjoiZW1haWwiLCJwcm92aWRlcnMiOlsiZW1haWwiXX0sInVzZXJfbWV0YWRhdGEiOnsiZW1haWxfdmVyaWZpZWQiOnRydWV9LCJyb2xlIjoiYXV0aGVudGljYXRlZCIsImFhbCI6ImFhbDEiLCJhbXIiOlt7Im1ldGhvZCI6InBhc3N3b3JkIiwidGltZXN0YW1wIjoxNzg0Mzg0NTY5fV0sInNlc3Npb25faWQiOiIwYWI0ODcxNS00Y2QwLTRlZGItYWM3Yi03OTBjNzFkNjY2OGIiLCJpc19hbm9ueW1vdXMiOmZhbHNlfQ.3ES-M0Dw6rOmkj5N46SnvUacxn3VBOPatvOBdcRWcvNosyqSm8xcmZrmvsbKGMb6qU2ID4fbuVmWRq__MTFctg';

export default function () {
  // We simulate a user opening the app, viewing inventory, checking a recipe, and sending an async generation request

  // 1. Check Health/Metrics
  let res1 = http.get(`${BASE_URL}/api/v1/health`);
  check(res1, { 'status is 200': (r) => r.status === 200 });
  
  sleep(1);

  // 2. Fuzzy search for an ingredient (tests DB similarity search)
  let res2 = http.get(`${BASE_URL}/api/v1/ingredients/fuzzy?q=chicken`);
  check(res2, { 'fuzzy search status 200': (r) => r.status === 200 });

  sleep(1);

  // 3. Initiate an async recipe generation job (tests the new queue)
  const payload = JSON.stringify({
    ingredients: ['chicken', 'rice', 'broccoli'],
    servings: 2,
    cuisine: 'Asian',
    max_time_minutes: 30
  });

  const params = {
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${REAL_TOKEN}`
    },
  };

  let res3 = http.post(`${BASE_URL}/api/v1/ai/generate-recipe`, payload, params);
  check(res3, { 
    'generation async accepted': (r) => r.status === 200,
    'has job_id': (r) => r.json('job_id') !== undefined
  });

  if (res3.status === 200) {
    const jobId = res3.json('job_id');
    // 4. Poll the job status immediately
    let res4 = http.get(`${BASE_URL}/api/v1/jobs/${jobId}`);
    check(res4, { 'poll job success': (r) => r.status === 200 });
  }

  sleep(2);
}
