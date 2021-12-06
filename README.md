# Boston Tech Workers Coalition

Local Boston subdomain website.

## Quickstart

First, run `make` to build the project.

Then, open `.env` and `terraform.tfvars` and fill-in the appropriate `GOOGLE_*` values.

You can now run the app locally at [http://localhost:3000/](http://localhost:3000/) with `make up`

## Deploy

This repo is configured to auto-deploy on tagged commits via [GitHub Actions](https://github.com/techworkersco/twc-site-boston/actions). Simply commit your changes, **tag** the repo, and push to GitHub and it should do the rest!

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

or, to apply without an approval prompt:

```bash
make apply-auto [--dry-run]
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
- **S3 Bucket** — S3 bucket for storing terraform state
