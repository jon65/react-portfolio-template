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

# Build the application and verify standalone output
RUN npm run build && \
    if [ ! -d .next/standalone ]; then \
        echo "ERROR: .next/standalone not found after build!"; \
        echo "Checking Next.js version:"; \
        npm list next || true; \
        node -e "const config = require('./next.config.js'); console.log('Config:', JSON.stringify(config, null, 2));" || true; \
        exit 1; \
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