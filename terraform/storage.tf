resource "random_id" "suffix" {
  byte_length = 3
}

# Holds the SOAR code. Nodes cannot reach GitHub, so they pull code from here at boot.
resource "aws_s3_bucket" "code" {
  bucket        = "innovatech-soar-code-${random_id.suffix.hex}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "code" {
  bucket                  = aws_s3_bucket.code.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "soar_code" {
  for_each = toset(concat(
    tolist(fileset("${path.module}/../soar", "*.py")),
    tolist(fileset("${path.module}/../soar", "*.yaml")),
  ))
  bucket = aws_s3_bucket.code.id
  key    = each.value
  source = "${path.module}/../soar/${each.value}"
  etag   = filemd5("${path.module}/../soar/${each.value}")
}