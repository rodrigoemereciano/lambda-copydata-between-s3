data "archive_file" "my_lambda_function" {
  source_dir  = "${path.module}/lambda/"
  output_path = "${path.module}/lambda.zip"
  type        = "zip"
}


# policies

resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.env_name}_lambda_policy"
  description = "${var.env_name}_lambda_policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:CopyObject",
        "s3:HeadObject"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::${var.env_name}-src-bucket",
        "arn:aws:s3:::${var.env_name}-src-bucket/*"
      ]
    },
    {
      "Action": [
        "s3:ListBucket",
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:CopyObject",
        "s3:HeadObject"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::${var.env_name}-dst-bucket",
        "arn:aws:s3:::${var.env_name}-dst-bucket/*"
      ]
    },
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

# role
resource "aws_iam_role" "s3_copy_function" {
    name = "app_${var.env_name}_lambda"

    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}


# atachar role

resource "aws_iam_role_policy_attachment" "terraform_lambda_iam_policy_basic_execution" {
 role = "${aws_iam_role.s3_copy_function.id}"
 policy_arn = "${aws_iam_policy.lambda_policy.arn}"
}


# permitir bucket s3 permission de gatilho ou lambda function
resource "aws_lambda_permission" "allow_terraform_bucket" {
   statement_id = "AllowExecutionFromS3Bucket"
   action = "lambda:InvokeFunction"
   function_name = "${aws_lambda_function.s3_copy_function.arn}"
   principal = "s3.amazonaws.com"
   source_arn = "${aws_s3_bucket.source_bucket.arn}"
}

#lambda function
resource "aws_lambda_function" "s3_copy_function" {
   filename = "lambda.zip"
   source_code_hash = data.archive_file.my_lambda_function.output_base64sha256
   function_name = "${var.env_name}_s3_copy_lambda"
   role = "${aws_iam_role.s3_copy_function.arn}"
   handler = "index.lambda_handler"
   runtime = "python3.9"

   environment {
       variables = {
           DST_BUCKET = "${var.env_name}-dst-bucket",
           REGION = "${var.aws_region}"
       }
   }
}

# Usar o ObjectCreated para saber quando um novo arquivo foi criado/adicionado no bucket s3
resource "aws_s3_bucket_notification" "bucket_terraform_notification" {
    bucket = "${aws_s3_bucket.source_bucket.id}"
    lambda_function {
        lambda_function_arn = "${aws_lambda_function.s3_copy_function.arn}"
        events = ["s3:ObjectCreated:*"]
    }

    depends_on = [ aws_lambda_permission.allow_terraform_bucket ]
}

# criar buckets s3
resource "aws_s3_bucket" "source_bucket" {
   bucket = "${var.env_name}-src-bucket"
   force_destroy = true
}

resource "aws_s3_bucket" "destination_bucket" {
   bucket = "${var.env_name}-dst-bucket"
   force_destroy = true
}

