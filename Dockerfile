ARG RUNTIME=nodejs12.x
ARG TERRAFORM=latest

# Lock NodeJS dependencies
FROM lambci/lambda:build-${RUNTIME} AS lock
COPY index.js package*.json /var/task/
RUN npm install --production

# Dev environment
FROM lambci/lambda:build-${RUNTIME} AS dev
COPY --from=lock /var/task/ .
RUN npm install

# Zip Lambda package
FROM lambci/lambda:build-${RUNTIME} AS zip
COPY --from=lock /var/task/ .
RUN zip -r /var/task/package.zip node_modules website index.js package*.json

# Plan terraform
FROM hashicorp/terraform:${TERRAFORM} AS plan
WORKDIR /var/task/
COPY *.tf /var/task/
COPY --from=zip /var/task/package.zip .
ARG AWS_ACCESS_KEY_ID
ARG AWS_DEFAULT_REGION=us-east-1
ARG AWS_SECRET_ACCESS_KEY
RUN terraform fmt -check
RUN terraform init
ARG TF_VAR_BUILD
RUN terraform plan -out terraform.zip
CMD ["apply", "terraform.zip"]
