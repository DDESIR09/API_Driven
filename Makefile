.PHONY: install ec2-create lambda-deploy api-create status start stop clean

# Variables
INSTANCE_ID := i-afff854eb5fd8f883
API_ID := $(shell awslocal apigateway get-rest-apis --query 'items[?name==`ec2-api`].id' --output text)
API_URL := http://localhost:4566/restapis/$(API_ID)/dev/_user_request_/ec2

install:
	@echo "Installation de awslocal..."
	pip install awscli-local

ec2-create:
	@echo "Creation de l'instance EC2..."
	awslocal ec2 run-instances \
		--image-id ami-07b643b5e45e \
		--instance-type t2.micro \
		--key-name ma-cle \
		--count 1

lambda-deploy:
	@echo "Deploiement de la Lambda..."
	zip -r lambda_function.zip lambda_function.py
	awslocal lambda create-function \
		--function-name ec2-controller \
		--runtime python3.11 \
		--handler lambda_function.lambda_handler \
		--role arn:aws:iam::000000000000:role/lambda-ec2-role \
		--zip-file fileb://lambda_function.zip \
		--timeout 30

status:
	@curl -s "$(API_URL)?action=status" | python3 -m json.tool

start:
	@curl -s "$(API_URL)?action=start" | python3 -m json.tool

stop:
	@curl -s "$(API_URL)?action=stop" | python3 -m json.tool

clean:
	rm -f lambda_function.zip response.json
