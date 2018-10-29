# Boston Tech Workers Coalition

Local Boston subdomain website.

## Setup

Copy both [`./.env.example`](./.env.example) and [`.terraform.tfvars.example`](./terraform.tfvars.example) to `.env` and `terraform.tfvars`, respectively. Fill both files with your AWS keys and S3 information.

Source the `.env` file:

```bash
source .env
```

## Build

Use the [`docker-compose.yml`](./docker-compose.yml) file to build and deploy the Lambda package:

```bash
docker-compose run --rm package
```

This will mount the local [`src`](./src) and `dist` directories into a container instance of the `lambci/lambda:build-nodejs8.10` image, install required node modules, compress the package into a zip archive, move the package to `dist`, and copy the package to S3.

## Deploy

Deploy this project using [`terraform`](https://terraform.io).

```bash
# Initialize terraform
terraform init

# View pending changes to infrastructure
terraform plan

# Apply pending changes
terraform apply
```

## Infrastructure

The project will install the following AWS components:

- **Lambda** — A function to serve the website
- **API Gateway** — Web service to invoke the Lambda
- **ACM Certificate** — An Amazon-issued SSL certificate for `boston.techworkerscoalition.org`
- **Custom Domain** — Custom domain mapping the API to `boston.techworkerscoalition.org` using the above ACM certificate
- **S3 Bucket** — S3 bucket for:
  - Serving static assets to support the website
  - Hosting the Lambda package zip
  - Storing the terraform state file

There is a bit of circular logic involved in creating the S3 Bucket (the project creates the bucket and stores its state in the self-same bucket). This is not a big deal in practice, but could be confusing. To avoid, simply comment-out or temporarily remove the `backend.tf` file and re-add after the bucket has been created.
