# State is local for now — fine for a single-operator bring-up.
#
# To move to S3 (do this once the state matters):
#   1. Create the bucket (playground account):
#        aws s3api create-bucket --bucket mattrobenolt-tofu-state \
#          --region us-west-2 --create-bucket-configuration LocationConstraint=us-west-2 \
#          --profile playground-ops
#        aws s3api put-bucket-versioning --bucket mattrobenolt-tofu-state \
#          --versioning-configuration Status=Enabled --profile playground-ops
#   2. Uncomment the block below.
#   3. tofu init -migrate-state
#
# Modern aws providers use the lockfile for concurrency control; no DynamoDB
# table needed.
#
# terraform {
#   backend "s3" {
#     bucket       = "mattrobenolt-tofu-state"
#     key          = "launchpad/terraform.tfstate"
#     region       = "us-west-2"
#     profile      = "playground-ops"
#     use_lockfile = true
#     encrypt      = true
#   }
# }
