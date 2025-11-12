# Use Node.js 20 LTS (Medusa requires >=20)
FROM node:20.18.0-alpine

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies (npm ci is too strict, use npm install with lock file)
RUN npm install --production=false

# Copy application code
COPY . .

# Build the application
RUN npm run build

# Expose port
EXPOSE 9000

# Set environment to production
ENV NODE_ENV=production

# Start the application
CMD ["npm", "run", "start"]
