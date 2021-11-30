ARG NODE_VERSION=14
FROM public.ecr.aws/lambda/nodejs:${NODE_VERSION}
COPY . .
RUN yum install -y zip
RUN npm install --production
RUN zip -9r package.zip node_modules website index.js package*.json
RUN npm install
EXPOSE 3000
CMD ["npm", "start"]
