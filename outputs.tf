output "website_url" {
  value = format("http://%s", aws_s3_bucket_website_configuration.site.website_endpoint)
  description = "URL of S3 static"
}
