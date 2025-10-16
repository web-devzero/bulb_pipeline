provider "aws" {
    region = "us-east-1"
}

resource "aws_s3_bucket" "basxy_backend_codepipeline_artifact_bucket" {
  bucket = "basxy-backend-codepipeline-artifact-bucket"
}

resource "aws_iam_role" "basxy_backend_codepipeline_role" {
  name = "basxy_backend_codepipeline_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "basxy_backend_codepipline_role_policy" {
  name        = "basxy_backend_codepipline_role_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "codebuild:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_policy_attachment" "basxy_backend_codepipeline_role_policy_attachment" {
  name       = "basxy_backend_codepipeline_role_policy_attachment"
  roles      = [aws_iam_role.basxy_backend_codepipeline_role.name]
  policy_arn = aws_iam_policy.basxy_backend_codepipline_role_policy.arn
}

resource "aws_iam_role" "basxy_backend_codebuild_role" {
  name = "basxy_backend_codebuild_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "basxy_backend_codebuild_role_policy" {
  name        = "basxy_backend_codebuild_role_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "logs:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "dynamodb:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "ssm:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "basxy_backend_codebuild_role_policy_attachment" {
  name       = "basxy_backend_codebuild_role_policy_attachment"
  roles      = [aws_iam_role.basxy_backend_codebuild_role.name]
  policy_arn = aws_iam_policy.basxy_backend_codebuild_role_policy.arn
}

resource "aws_codebuild_project" "basxy_backend_codebuild_build" {
  name           = "basxy_backend_codebuild_build"
  service_role = aws_iam_role.basxy_backend_codebuild_role.arn
  artifacts {
    type = "CODEPIPELINE"
  }
  environment {
    compute_type                = "BUILD_GENERAL1_LARGE"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type            = "CODEPIPELINE"
    buildspec       = "buildspec_build.yml"
  }
}

resource "aws_codebuild_project" "basxy_backend_codebuild_deploy" {
  name           = "basxy_backend_codebuild_deploy"
  service_role = aws_iam_role.basxy_backend_codebuild_role.arn
  artifacts {
    type = "CODEPIPELINE"
  }
  environment {
    compute_type                = "BUILD_GENERAL1_LARGE"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

  }
  source {
    type            = "CODEPIPELINE"
    buildspec       = "buildspec_deploy.yml"
  }
}

resource "aws_codepipeline" "basxy_backend_pipeline" {
  name     = "basxy_backend_pipeline"
  role_arn = aws_iam_role.basxy_backend_codepipeline_role.arn
  artifact_store {
    location = aws_s3_bucket.basxy_backend_codepipeline_artifact_bucket.bucket
    type     = "S3"
  }
  stage {
    name = "Source"
    action {
      name             = "Commit"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        Owner          = "web-devzero"
        Repo           = "bulb_pipeline"
        Branch         = "main"
        OAuthToken     = data.aws_ssm_parameter.basxy_github_token.value
      }
    }
  }
  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName    = aws_codebuild_project.basxy_backend_codebuild_build.id
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name             = "Deploy"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["deploy_output"]
      version          = "1"

      configuration = {
        ProjectName    = aws_codebuild_project.basxy_backend_codebuild_deploy.id
      }
    }
  }

}