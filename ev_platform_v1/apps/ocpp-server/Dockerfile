FROM node:20-alpine AS builder

WORKDIR /app

# Copy root workspace config
COPY package*.json ./
COPY tsconfig*.json ./

# Copy packages and apps
COPY packages ./packages
COPY apps/ocpp-server ./apps/ocpp-server

# Install dependencies
RUN npm install

# Build shared package first
RUN npm run build -w packages/shared

# Build application
RUN npm run build -w apps/ocpp-server

# Production stage
FROM node:20-alpine

WORKDIR /app

COPY --from=builder /app/package*.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/packages/shared/dist ./packages/shared/dist
COPY --from=builder /app/packages/shared/package.json ./packages/shared/
COPY --from=builder /app/apps/ocpp-server/dist ./apps/ocpp-server/dist
COPY --from=builder /app/apps/ocpp-server/package.json ./apps/ocpp-server/

CMD ["npm", "start", "-w", "apps/ocpp-server"]
