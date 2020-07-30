ARG RUNTIME=nodejs12.x
FROM lambci/lambda:build-${RUNTIME}
COPY . .
RUN npm install --production
RUN zip -9r package.zip node_modules website index.js package*.json
RUN npm install
EXPOSE 3000
CMD ["npm", "start"]
