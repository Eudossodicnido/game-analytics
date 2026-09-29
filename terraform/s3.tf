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

