build: .env terraform.tfvars package.zip

clean:
	rm -rf src/node_modules package.zip

deploy: build .terraform
	terraform apply -auto-approve

plan: build .terraform
	terraform plan

logs:
	aws logs tail /aws/lambda/website --follow

start: build
	cd src && npm start

.PHONY: build clean deploy plan logs start

.env:
	cp $@.example $@

.terraform: *.tf
	terraform init
	touch $@

package.zip: src/node_modules src/views/* src/index.js src/package*.json
	cd src && zip -9qr ../$@ node_modules views index.js package*.json

src/node_modules: src/package.json
	cd src && npm install
	touch $@

terraform.tfvars:
	echo 'GOOGLE_API_KEY = "<fill-me-in>"' >> $@
