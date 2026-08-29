import express from 'express';
import { createClient } from 'redis';
import Stripe from 'stripe';
import OpenAI from 'openai';

const app = express();
const PORT = process.env.PORT || 3001;

// Database connection
const DATABASE_URL = process.env.DATABASE_URL;
if (!DATABASE_URL) {
  throw new Error('DATABASE_URL is required');
}

// Redis for caching + job queue signaling
const REDIS_URL = process.env.REDIS_URL;  // worker polls this
const redis = createClient({ url: REDIS_URL });

// Auth secret — rotates weekly, stored in secrets manager in production
const JWT_SECRET = process.env.JWT_SECRET;
if (!JWT_SECRET) {
  throw new Error('JWT_SECRET is required — generate with: openssl rand -base64 32');
}

// Payments
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY || '', {
  apiVersion: '2023-10-16',
});

// AI (used for smart search and auto-categorization features)
const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

app.use(express.json());

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', version: '1.0.0' });
});

app.listen(PORT, () => {
  console.log(`API running on port ${PORT}`);
});

export default app;
