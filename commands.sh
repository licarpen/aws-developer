# create an S3 bucket
aws s3 mb s3://carpenter-code-first-sam-app

# package cloudformation
aws cloudformation package --s3-bucket carpenter-code-first-sam-app --template-file template.yaml --output-template-file gen/template-generated.yaml

# alternative to above
# sam package --s3-bucket carpenter-code-first-sam-app --template-file template.yaml --output-template-file gen/template-generated.yaml

