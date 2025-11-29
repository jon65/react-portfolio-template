/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  swcMinify: true,
  // Enable standalone output for Docker
  output: 'standalone',
}

// Verify the config is correct
if (process.env.NODE_ENV === 'production') {
  console.log('Next.js config loaded:', JSON.stringify(nextConfig, null, 2));
}

module.exports = nextConfig
