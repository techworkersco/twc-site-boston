ARG RUNTIME=nodejs10.x

FROM lambci/lambda:build-${RUNTIME}

# Create Lambda package
COPY website .
RUN zip -r /var/task/package.lambda.zip .

# Create Lambda layer package
COPY package*.json /opt/nodejs/
WORKDIR /opt/nodejs
RUN npm install --package-lock-only
RUN npm install --production
WORKDIR /opt/
RUN zip -r /var/task/package.layer.zip .
WORKDIR /var/task/

# Terraform
ARG AWS_ACCESS_KEY_ID
ARG AWS_DEFAULT_REGION
ARG AWS_SECRET_ACCESS_KEY
ARG TF_VAR_release
COPY --from=hashicorp/terraform:0.12.1 /bin/terraform /bin/
COPY terraform.tf .
RUN terraform init
RUN terraform fmt -check
RUN terraform plan -out terraform.zip
CMD ["terraform", "apply", "terraform.zip"]
