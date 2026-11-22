data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "aws_security_group" "api" {
  name        = "${var.project_name}-api"
  description = "SSH para el despliegue y HTTP para la API"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "deploy" {
  key_name   = "${var.project_name}-deploy"
  public_key = file(pathexpand(var.public_key_path))
}

# La API sube las fotos con este rol, asi el servidor no guarda llaves de AWS.
resource "aws_iam_role" "api" {
  name = "${var.project_name}-api"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "upload_photos" {
  name = "subir-fotos"
  role = aws_iam_role.api.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "s3:PutObject"
      Resource = "${aws_s3_bucket.photos.arn}/reports/*"
    }]
  })
}

resource "aws_iam_instance_profile" "api" {
  name = "${var.project_name}-api"
  role = aws_iam_role.api.name
}

resource "aws_instance" "api" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.deploy.key_name
  vpc_security_group_ids = [aws_security_group.api.id]
  iam_instance_profile   = aws_iam_instance_profile.api.name

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  # Hop limit 2 para que el contenedor de la API alcance las credenciales del rol (IMDSv2).
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  user_data_replace_on_change = true
  user_data = templatefile("${path.module}/templates/user_data.sh.tftpl", {
    docker_image   = var.docker_image
    aws_region     = var.aws_region
    bucket_name    = aws_s3_bucket.photos.bucket
    db_name        = var.db_name
    db_user        = var.db_user
    db_password    = var.db_password
    mailer_service = var.mailer_service
    mailer_user    = var.mailer_user
    mailer_token   = var.mailer_token
    mailer_crew    = var.mailer_crew
    noip_username  = var.noip_username
    noip_password  = var.noip_password
    noip_hostname  = var.noip_hostname
  })

  tags = {
    Name = "${var.project_name}-api"
  }
}
