# ---- Stage 1: dependências de produção ----
FROM node:20-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev

# ---- Stage 2: imagem final (enxuta) ----
FROM node:20-alpine AS production
ENV NODE_ENV=production
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY package.json server.js ./
EXPOSE 3000
USER node
CMD ["node", "server.js"]
