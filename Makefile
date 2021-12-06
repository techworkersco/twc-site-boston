all: .env terraform.tfvars app/node_modules package.zip

build: package.zip

clean:
	rm -rf app/node_modules build package.zip

up: .env app/node_modules
	cd app && npm start

plan: package.zip | .terraform
	terraform plan

apply: package.zip | .terraform
	terraform apply

apply-auto: package.zip | .terraform
	terraform apply -auto-approve

.PHONY: all build clean up plan apply apply-auto

package.zip: app/*.js app/*.json app/views/*
	mkdir -p build
	cp app/package*.json build
	cp app/app.js build
	cp app/index.js build
	cp -r app/views build/views
	cd build && npm install --production
	cd build && zip -9r ../$@ *

app/node_modules: app/package.json
	cd app && npm install

terraform.tfvars:
	echo 'GOOGLE_API_KEY     = "<fill-me-in>"' >> $@
	echo 'GOOGLE_CALENDAR_ID = "<fill-me-in>"' >> $@

.env:
	cp $@.example $@

.terraform: *.tf
	terraform init && touch .terraform || rm -rf .terraform
