# --- build image ---
FROM node:latest AS build
WORKDIR /usr/src/app
COPY package*.json /usr/src/app/
RUN npm install

# --- production image ---
FROM node:lts-slim
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install dumb-init -y \
    && apt-get clean \
    && apt-get autoclean
ENV NODE_ENV production
USER node
WORKDIR /usr/src/app
COPY --chown=node:node --from=build /usr/src/app/node_modules /usr/src/app/node_modules
COPY --chown=node:node . /usr/src/app
EXPOSE 3000
CMD ["dumb-init", "node", "app.js"]