# root/backend.tf (or global/backend.tf)
# This file defines the *shared* bucket and table for state.
# The 'key' will still need to be unique per environment, usually set in a `main.tf`
# or via CLI, or through a `partial configuration` during `terraform init`.

terraform {
  backend "s3" {}
}