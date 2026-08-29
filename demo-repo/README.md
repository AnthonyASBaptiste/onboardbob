# demo-api-platform

A sample Node/Python microservices repo for OnboardBob demos.

## Getting Started

Make sure you have Node 18 installed. Then:

```
npm install
npm start
```

## Environment Variables

Copy `.env.example` to `.env` and fill in the required values.

## Services

- `api` — REST API (Node/Express) on port 3001
- `worker` — Background job processor (Python) 
- `dashboard` — Frontend (Node/React) on port 3000
