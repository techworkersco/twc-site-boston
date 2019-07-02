# Boston Tech Workers Coalition

Local Boston subdomain website.

## Setup

Copy `.env.example` to `.env` and fill with your AWS/Google keys and S3 information.

Install dependencies:

```bash
npm install
```

Run a development server with:

```bash
npm start
```

## Build & Deploy

You will need [GNU Make](https://www.gnu.org/software/make/) and [Docker](https://docs.docker.com/install/) installed in order to build and deploy this project. [Terraform](https://terraform.io) is used in Docker to manage infrastructure.

Build the Lambda package with:

```bash
make
```

Generate a terraform plan with:

```bash
make plan
```

Update infrastructure with:

```bash
make apply
```

Clean up any generated artifacts with:

```bash
make clean
```

## Infrastructure

The project manages the following AWS components:

- **Lambda** — A function to serve the website
- **API Gateway** — Web service to invoke the Lambda
- **ACM Certificate** — An Amazon-issued SSL certificate for `boston.techworkerscoalition.org`
- **Custom Domain** — Custom domain mapping the API to `boston.techworkerscoalition.org` using the above ACM certificate
- **S3 Bucket** — S3 bucket for serving static assets to support the website and hosting the Lambda package
