# Boston Tech Workers Coalition

Local Boston subdomain website.

## Setup

Copy both [`./.env.example`](./.env.example) and [`.terraform.tfvars.example`](./terraform.tfvars.example) to `.env` and `terraform.tfvars`, respectively. Fill both files with your AWS keys and S3 information.

Install dependencies:

```bash
npm install

# or..

docker-compose run npm install
```

Run a development server with:

```bash
npm start
```

## Build & Deploy

Update the version in `terraform.tfvars` and use the custom `npm` scripts to build and deploy.

Build the package with:

```bash
npm run init
```

Deploy to AWS with:

```bash
npm run apply
```

This project uses [Docker](https://docker.com) [Terraform](https://terraform.io) to build and deploy a package for AWS Lambda.

That is to say, the `npm` scripts above are shortcuts for:

```bash
# Build package and initialize Terraform
docker-compose run build && terraform init

# Deploy to AWS
terraform apply
```

## Infrastructure

The project will install the following AWS components:

- **Lambda** — A function to serve the website
- **API Gateway** — Web service to invoke the Lambda
- **ACM Certificate** — An Amazon-issued SSL certificate for `boston.techworkerscoalition.org`
- **Custom Domain** — Custom domain mapping the API to `boston.techworkerscoalition.org` using the above ACM certificate
- **S3 Bucket** — S3 bucket for serving static assets to support the website and hosting the Lambda package
