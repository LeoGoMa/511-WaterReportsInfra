resource "aws_s3_bucket" "photos" {
  bucket        = var.bucket_name
  force_destroy = true # terraform destroy borra el bucket aunque tenga fotos
}

resource "aws_s3_bucket_public_access_block" "photos" {
  bucket = aws_s3_bucket.photos.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = false
  restrict_public_buckets = false
}

# Las fotos se leen publicamente para que se vean en el front y en el correo.
resource "aws_s3_bucket_policy" "public_read_reports" {
  bucket     = aws_s3_bucket.photos.id
  depends_on = [aws_s3_bucket_public_access_block.photos]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.photos.arn}/reports/*"
    }]
  })
}
