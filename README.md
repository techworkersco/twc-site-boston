# Boston Tech Workers Coalition

Local Boston subdomain website.

## Quickstart

First, run `make .env` and fill the appropriate values into the file.

Then run a local web server natively or with Docker.

### Docker (recommended)

Use `make` to build a Docker image and run start a container running the web server:

```bash
make up [--dry-run]
```

### NodeJS

Install node modules and start server:

```bash
npm install
npm start
```

Navigate to [localhost:3000](http://localhost:3000) to see an instance of the website running locally.

## Build & Deploy

This repo is configured to auto-deploy on tagged commits via [GitHub Actions](https://github.com/techworkersco/twc-site-boston/actions). Simply commit your changes, **tag** the repo and push to GitHub and Travis should do the rest!

[Terraform](https://terraform.io) is used to manage infrastructure.

Build the Lambda package with:

```bash
make [--dry-run]
```

Generate a terraform plan with:

```bash
make plan [--dry-run]
```

Update infrastructure with:

```bash
make apply [--dry-run]
```

Clean up any generated artifacts with:

```bash
make clean [--dry-run]
```

## Infrastructure

The project manages the following AWS components:

- **Lambda** — A function to serve the website
- **API Gateway** — Web service to invoke the Lambda
- **ACM Certificate** — An Amazon-issued SSL certificate for `boston.techworkerscoalition.org`
- **Custom Domain** — Custom domain mapping the API to `boston.techworkerscoalition.org` using the above ACM certificate
- **S3 Bucket** — S3 bucket for serving static assets to support the website and hosting the Lambda package
