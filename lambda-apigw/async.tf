
resource "aws_sns_topic" "payment_notification" {
  name = "payment-notifications-topic"
}

resource "aws_sns_topic_subscription" "payment_notification_email_subscription" {
  topic_arn = aws_sns_topic.payment_notification.arn
  protocol  = "email"
  endpoint  = "suraj.v.bangera@gmail.com"
}