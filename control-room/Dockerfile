FROM node
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install --quiet || npm install --quiet
COPY . .
RUN npm run build
USER node
EXPOSE 3000
CMD ["npm","run","start"]
