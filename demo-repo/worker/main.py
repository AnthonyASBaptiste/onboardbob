import redis
import os
import json
import time
import requests

# Redis connection for job queue
REDIS_URL = os.environ.get('REDIS_URL')
DATABASE_URL = os.environ.get('DATABASE_URL')
OPENAI_API_KEY = os.environ.get('OPENAI_API_KEY')

# Worker polls api/health before starting to process jobs
# This ensures the API is fully initialized before workers consume queue items
API_BASE_URL = os.environ.get('API_BASE_URL', 'http://api:3001')

QUEUE_NAME = 'jobs:default'


def wait_for_api():
    """Block until the API service is healthy."""
    retries = 0
    while retries < 30:
        try:
            resp = requests.get(f'{API_BASE_URL}/health', timeout=2)
            if resp.status_code == 200:
                print('[worker] API is healthy, starting job processing')
                return
        except Exception:
            pass
        retries += 1
        time.sleep(2)
    raise RuntimeError('API did not become healthy in time')


def process_job(job: dict):
    """Process a single job from the queue."""
    job_type = job.get('type')
    payload = job.get('payload', {})
    print(f'[worker] Processing job: {job_type}')
    # Job handlers go here


def main():
    wait_for_api()

    client = redis.from_url(REDIS_URL)
    print('[worker] Listening for jobs...')

    while True:
        result = client.brpop(QUEUE_NAME, timeout=5)
        if result:
            _, raw = result
            job = json.loads(raw)
            process_job(job)


if __name__ == '__main__':
    main()
