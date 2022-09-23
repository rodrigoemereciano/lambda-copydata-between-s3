output "Source-S3-bucket" {
 value = "${aws_s3_bucket.source_bucket.id}"
}

output "Destination-S3-bucket" {
 value = "${aws_s3_bucket.destination_bucket.id}"
}

output "module" {
  value = "${path.module }"
  
}