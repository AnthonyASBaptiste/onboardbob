import OpenAI from 'openai';
import { createClient } from 'redis';

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,  // required for smart search feature
});

const redis = createClient({
  url: process.env.REDIS_URL,
});

export async function generateEmbedding(text: string): Promise<number[]> {
  const response = await openai.embeddings.create({
    model: 'text-embedding-3-small',
    input: text,
  });
  return response.data[0].embedding;
}

export async function semanticSearch(query: string, limit = 10) {
  const embedding = await generateEmbedding(query);
  // Cache embeddings in Redis to reduce API calls
  const cacheKey = `embed:${Buffer.from(query).toString('base64')}`;
  await redis.setEx(cacheKey, 3600, JSON.stringify(embedding));
  return embedding;
}
