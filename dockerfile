# Multi-stage build for optimized image size

# Stage 1: Dependencies
FROM node:16-alpine AS deps
WORKDIR /app

# Copy package files
COPY package.json package-lock.json* ./

# Install dependencies
RUN npm ci --legacy-peer-deps

# Stage 2: Builder
FROM node:16-alpine AS builder
WORKDIR /app

# Copy dependencies from deps stage
COPY --from=deps /app/node_modules ./node_modules

# Copy package files and config first
COPY package.json package-lock.json* ./
COPY next.config.js ./

# Copy all source files
COPY . .

# Set environment variables for build
ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_ENV=production

# Verify next.config.js has standalone output configured
RUN echo "=== Verifying next.config.js ===" && \
    cat next.config.js && \
    (grep -q "output.*standalone" next.config.js || grep -q "output: 'standalone'" next.config.js) && \
    echo "✓ Standalone output configured in next.config.js"

# Verify config is being read before build
RUN echo "=== Testing next.config.js ===" && \
    node -e "const config = require('./next.config.js'); console.log('Config output:', config.output); console.log('Full config:', JSON.stringify(config, null, 2));" && \
    echo "✓ Config loaded successfully"

# Build the application
RUN npm run build

# Debug: Check what was created
RUN echo "=== Checking .next directory structure ===" && \
    ls -la .next/ && \
    echo "" && \
    echo "=== Checking for standalone ===" && \
    (test -d .next/standalone && (echo "✓ standalone directory found" && ls -la .next/standalone/) || echo "✗ standalone directory NOT found") && \
    echo "" && \
    echo "=== Checking for server ===" && \
    (test -d .next/server && (echo "✓ server directory found" && ls -la .next/server/) || echo "✗ server directory NOT found")

# Verify standalone output was created
RUN if [ ! -d .next/standalone ]; then \
        echo "ERROR: .next/standalone not found after build!"; \
        echo "This usually means:"; \
        echo "  1. next.config.js doesn't have 'output: \"standalone\"'"; \
        echo "  2. Next.js version doesn't support standalone output"; \
        echo "  3. Build failed silently"; \
        echo ""; \
        echo "Checking Next.js version:"; \
        npm list next || true; \
        echo ""; \
        echo "Checking if config was read:"; \
        node -e "const config = require('./next.config.js'); console.log('Config:', JSON.stringify(config, null, 2));" || true; \
        exit 1; \
    else \
        echo "✓ Standalone output verified"; \
        echo "Contents of .next/standalone:"; \
        ls -la .next/standalone/; \
    fi

# Stage 3: Runner (Production)
FROM node:16-alpine AS runner
WORKDIR /app

ENV NODE_ENV production
ENV NEXT_TELEMETRY_DISABLED 1

# Create a non-root user
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Copy necessary files from builder
COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json ./package.json

# Copy built application
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

# Switch to non-root user
USER nextjs

# Expose port
EXPOSE 3000

ENV PORT 3000

# Start the application
CMD ["node", "server.js"]