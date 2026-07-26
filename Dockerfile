FROM node:24-bookworm-slim

WORKDIR /app

RUN npm config set registry https://registry.npmjs.org/ && \
    yarn config set registry https://registry.npmjs.org/

# Copy the repository contents into the image and install all dependencies
COPY . .

# The container only runs the backend dev server, so strip Electron-only
# packages before installing to avoid downloading desktop binaries.
RUN node -e "const fs=require('fs');const pkg=JSON.parse(fs.readFileSync('package.json','utf8'));for(const section of ['dependencies','devDependencies']){if(!pkg[section]) continue;for(const name of ['custom-electron-titlebar','electron','electron-builder','electron-rebuild','electronmon']) delete pkg[section][name];}fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2)+'\n');" && \
    yarn install --frozen-lockfile && \
    yarn cache clean

# Build the backend bundle (data/serve/app.js) in production mode.
RUN yarn build

ENV NODE_ENV=prod
ENV PORT=10588

EXPOSE 10588

# Run the bundled backend server directly. NODE_ENV=prod is set above, so this
# is equivalent to `yarn start` (cross-env NODE_ENV=prod node data/serve/app.js).
CMD ["node", "data/serve/app.js"]