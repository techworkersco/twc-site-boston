# Boston Tech Workers Coalition

Local Boston subdomain website.

## Quickstart

First, copy `.env.example` to `.env` and fill in the appropriate values.

Then run a local web server natively or with Docker.

**Native**

Install node modules and start server:

```bash
npm install
npm start
```

**Docker**

Use `make` to build a Docker image and run start a container running the web server:

```bash
make up [--dry-run]
```

Navigate to [localhost:3000](http://localhost:3000) to see an instance of the website running locally.

## Build & Deploy

You will need [GNU Make](https://www.gnu.org/software/make/) and [Docker](https://docs.docker.com/install/) installed in order to build and deploy this project.

[Terraform](https://terraform.io) is used in Docker to manage infrastructure.

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

See all tasks that can be run using tab-completion on `make`:

```bash
make <tab>
```

## Infrastructure

The project manages the following AWS components:

- **Lambda** — A function to serve the website
- **API Gateway** — Web service to invoke the Lambda
- **ACM Certificate** — An Amazon-issued SSL certificate for `boston.techworkerscoalition.org`
- **Custom Domain** — Custom domain mapping the API to `boston.techworkerscoalition.org` using the above ACM certificate
- **S3 Bucket** — S3 bucket for serving static assets to support the website and hosting the Lambda package
