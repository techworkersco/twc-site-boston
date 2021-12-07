all: .env terraform.tfvars package.zip

build: package.zip

clean:
	rm -rf build package.zip

up: .env node_modules
	npm start

plan: package.zip | .terraform
	terraform plan

apply: package.zip | .terraform
	terraform apply

apply-auto: package.zip | .terraform
	terraform apply -auto-approve

.PHONY: all build clean up plan apply apply-auto

package.zip: app/*.js app/views/* node_modules
	mkdir -p build
	cp package*.json build
	cp app/index.js build
	cp -r app/views build/views
	cd build \
	&& npm install --production \
	&& zip -9qr ../$@ *

node_modules: package.json
	npm install && touch node_modules

terraform.tfvars:
	echo 'GOOGLE_API_KEY     = "<fill-me-in>"' >> $@
	echo 'GOOGLE_CALENDAR_ID = "<fill-me-in>"' >> $@

.env:
	cp $@.example $@

.terraform: *.tf
	terraform init && touch .terraform || rm -rf .terraform
