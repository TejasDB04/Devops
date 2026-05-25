const http = require('http');

function get(path, port = 3099) {
  return new Promise((resolve, reject) => {
    const req = http.get(`http://127.0.0.1:${port}${path}`, (res) => {
      let body = '';
      res.on('data', (c) => (body += c));
      res.on('end', () => resolve({ status: res.statusCode, body }));
    });
    req.on('error', reject);
  });
}

async function run() {
  process.env.PORT = '3099';
  const { startServer } = require('../app.js');
  const server = startServer(3099);
  await new Promise((r) => setTimeout(r, 500));

  try {
    const health = await get('/api/health');
    if (health.status !== 200) throw new Error(`health failed: ${health.status}`);

    const metrics = await get('/metrics');
    if (metrics.status !== 200 || !metrics.body.includes('k8s_app_')) {
      throw new Error('metrics endpoint missing prometheus metrics');
    }
    console.log('All tests passed');
  } finally {
    server.close();
  }
}

run().catch((err) => {
  console.error(err);
  process.exit(1);
});
