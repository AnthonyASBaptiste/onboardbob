export default function Home() {
  const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001';

  return (
    <main>
      <h1>Demo Dashboard</h1>
      <p>API: {apiUrl}</p>
    </main>
  );
}
