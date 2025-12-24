FROM node:18-alpine AS builder

WORKDIR /app

# Copy root workspace config
COPY package*.json ./
COPY tsconfig*.json ./

# Copy packages and apps
COPY packages ./packages
COPY apps/api-gateway ./apps/api-gateway

# Install dependencies
RUN npm install

# Build shared package first
RUN npm run build -w packages/shared

# Build application
RUN npm run build -w apps/api-gateway

# Production stage
FROM node:18-alpine

WORKDIR /app

COPY --from=builder /app/package*.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/packages/shared/dist ./packages/shared/dist
COPY --from=builder /app/packages/shared/package.json ./packages/shared/
COPY --from=builder /app/apps/api-gateway/dist ./apps/api-gateway/dist
COPY --from=builder /app/apps/api-gateway/package.json ./apps/api-gateway/

CMD ["npm", "start", "-w", "apps/api-gateway"]
