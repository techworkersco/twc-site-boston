ARG RUNTIME=nodejs10.x

FROM lambci/lambda:build-${RUNTIME} AS build

# Create Lambda package
COPY . .
RUN npm install --production
RUN zip -r /var/task/package.zip node_modules website index.js package*.json

# Validate terraform
FROM lambci/lambda:build-${RUNTIME} AS test
COPY --from=hashicorp/terraform:0.12.3 /bin/terraform /bin/
COPY --from=build /var/task/ .
RUN npm install
RUN terraform fmt -check

# Plan terraform
FROM lambci/lambda:build-${RUNTIME} AS plan
COPY --from=test /bin/terraform /bin/
COPY --from=test /var/task .
ARG AWS_ACCESS_KEY_ID
ARG AWS_DEFAULT_REGION
ARG AWS_SECRET_ACCESS_KEY
ARG TF_VAR_release
RUN terraform init
RUN terraform plan -out terraform.zip
CMD ["terraform", "apply", "terraform.zip"]
