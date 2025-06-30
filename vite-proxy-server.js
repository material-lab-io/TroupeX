const http = require('http');
const httpProxy = require('http-proxy');
const url = require('url');

// Create a proxy server
const proxy = httpProxy.createProxyServer({
  target: 'http://localhost:3036',
  ws: true,
  changeOrigin: true
});

// Handle errors
proxy.on('error', (err, req, res) => {
  console.error('Proxy error:', err);
  res.writeHead(500, { 'Content-Type': 'text/plain' });
  res.end('Proxy error');
});

// Create the server
const server = http.createServer((req, res) => {
  console.log(`Proxying: ${req.method} ${req.url}`);
  proxy.web(req, res);
});

// Handle WebSocket upgrades for HMR
server.on('upgrade', (req, socket, head) => {
  console.log('WebSocket upgrade:', req.url);
  proxy.ws(req, socket, head);
});

const PORT = 3037;
server.listen(PORT, () => {
  console.log(`Vite proxy server running on port ${PORT}`);
  console.log('Proxying requests to http://localhost:3036');
});