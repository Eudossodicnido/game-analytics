#Bucket
import {
  to = aws_s3_bucket.data_lake
  identity = {
    bucket = "rawg-pipeline-videogames-649473075374-eu-central-1-an"
  }
}

resource "aws_s3_bucket" "data_lake" {
  bucket = "rawg-pipeline-videogames-649473075374-eu-central-1-an"
  tags = {
    Project = "game-analytics"
  }
}

# Bucket ownership controls
import {
  to = aws_s3_bucket_ownership_controls.data_lake
  identity = {
    bucket = "rawg-pipeline-videogames-649473075374-eu-central-1-an"
  }
}

resource "aws_s3_bucket_ownership_controls" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Public access block
import {
  to = aws_s3_bucket_public_access_block.data_lake
  identity = {
    bucket = "rawg-pipeline-videogames-649473075374-eu-central-1-an"
  }
}

resource "aws_s3_bucket_public_access_block" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


# Server side encription
import {
  to = aws_s3_bucket_server_side_encryption_configuration.data_lake
  identity = {
    bucket = "rawg-pipeline-videogames-649473075374-eu-central-1-an"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    blocked_encryption_types = ["SSE-C"]
    bucket_key_enabled       = true
  }
}
