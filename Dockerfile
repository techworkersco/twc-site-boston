ARG RUNTIME=nodejs10.x
ARG TERRAFORM=latest

# Create Lambda package
FROM lambci/lambda:build-${RUNTIME} AS build
COPY . .
RUN npm install --production
RUN zip -r /var/task/package.zip node_modules website index.js package*.json
RUN npm install

# Plan terraform
FROM hashicorp/terraform:${TERRAFORM} AS plan
RUN apk add --no-cache python3 && pip3 install awscli
WORKDIR /var/task/
COPY --from=build /var/task/ .
ARG AWS_ACCESS_KEY_ID
ARG AWS_DEFAULT_REGION=us-east-1
ARG AWS_SECRET_ACCESS_KEY
ARG TF_VAR_release
RUN terraform init
RUN terraform plan -out terraform.zip
CMD ["apply", "terraform.zip"]
