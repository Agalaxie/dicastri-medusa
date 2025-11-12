# Use Node.js 20 LTS (Medusa requires >=20)
FROM node:20.18.0-alpine

# Set working directory
WORKDIR /app

# Install Yarn globally
RUN corepack enable && corepack prepare yarn@stable --activate

# Copy package files (including yarn.lock)
COPY package.json yarn.lock ./

# Install dependencies using Yarn
RUN yarn install --frozen-lockfile

# Copy application code
COPY . .

# Build the application
RUN yarn build

# Expose port
EXPOSE 9000

# Set environment to production
ENV NODE_ENV=production

# Start the application
CMD ["yarn", "start"]
