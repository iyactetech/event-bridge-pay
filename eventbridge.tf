module "eventbridge" {
  source  = "terraform-aws-modules/eventbridge/aws"
  version = "~> 3.0"

  create_bus = true
  bus_name   = "payments-bus"

  rules = {
    payment_created_rule = {
      description = "Trigger Lambda when a payment is created"
      event_pattern = jsonencode({
        source      = ["payments.api"]
        "detail-type" = ["payment.created"]
      })

      targets = [
        {
          name = "lambdaTarget"
          arn  = module.lambda_eventbridge_logger.lambda_function_arn
        }
      ]
    }
  }
}
