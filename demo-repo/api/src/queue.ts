import redis from 'redis';

// Job queue for background processing
// NOTE: worker service polls this queue — it depends on api/health being up
// before it begins processing. See docker-compose.yml depends_on.
const REDIS_URL = process.env.REDIS_URL;
const QUEUE_NAME = 'jobs:default';

const client = redis.createClient({ url: REDIS_URL });

export async function enqueueJob(type: string, payload: object) {
  const job = JSON.stringify({ type, payload, created: Date.now() });
  await client.lPush(QUEUE_NAME, job);
}

export async function dequeueJob() {
  const result = await client.brPop(QUEUE_NAME, 5);
  if (!result) return null;
  return JSON.parse(result.element);
}
