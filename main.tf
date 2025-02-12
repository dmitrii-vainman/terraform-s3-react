provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "site" {
  bucket = var.site_name
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.site.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_ownership_controls" "site" {
  bucket = aws_s3_bucket.site.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "site" {
  bucket = aws_s3_bucket.site.id

  acl = "public-read"
  depends_on = [
    aws_s3_bucket_ownership_controls.site,
    aws_s3_bucket_public_access_block.site
  ]
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource = [
          aws_s3_bucket.site.arn,
          "${aws_s3_bucket.site.arn}/*",
        ]
      },
    ]
  })

  depends_on = [
    aws_s3_bucket_public_access_block.site
  ]
}

resource "aws_s3_object" "react_build" {
  for_each = fileset("./dist", "**/*")

  bucket       = aws_s3_bucket.site.id
  key          = each.value
  source       = "./dist/${each.value}"
  content_type = lookup({
    html  = "text/html"
    css   = "text/css"
    js    = "application/javascript"
    json  = "application/json"
    png   = "image/png"
    jpg   = "image/jpeg"
    jpeg  = "image/jpeg"
    svg   = "image/svg+xml"
    webp  = "image/webp"
    ttf   = "font/ttf"
    woff  = "font/woff"
    woff2 = "font/woff2"
  }, regex("\\.([^.]+)$", each.value)[0], "application/octet-stream")

  acl = "public-read"
}


resource "aws_s3_object" "error" {
  bucket       = aws_s3_bucket.site.id
  key          = "error.html"
  source       = "./dist/index.html" # Use index.html for React routing
  content_type = "text/html"
  acl          = "public-read"
}

