resource "aws_ssm_parameter" "db_host" {
  name  = "/billing/db_host"
  type  = "String"
  value = module.rds_database.db_instance_endpoint
}

resource "aws_ssm_parameter" "db_user" {
  name  = "/billing/db_user"
  type  = "String"
  value = "payments_admin"
}

resource "aws_ssm_parameter" "db_password" {
  name  = "/billing/db_password"
  type  = "SecureString"
  value = random_password.db_password.result
}


resource "aws_ssm_parameter" "db_name" {
  name  = "/billing/db_name"
  type  = "String"
  value = var.db_name
}
