# AguaFix Infra

Infraestructura de AguaFix en AWS con Terraform. Nada se crea a mano en la consola de AWS.

Repositorios relacionados:

- API: [511-WaterReportsApi](https://github.com/LeoGoMa/511-WaterReportsApi)
- Front: [511-WaterReportsFront](https://github.com/LeoGoMa/511-WaterReportsFront)

## Que crea

| Recurso                                   | Para que                                                    |
| ----------------------------------------- | ----------------------------------------------------------- |
| `aws_security_group.api`                  | Abre el puerto 22 (SSH del despliegue) y el 80 (API)        |
| `aws_key_pair.deploy`                     | Registra la llave publica SSH en AWS                        |
| `aws_instance.api`                        | EC2 Ubuntu 24.04; su `user_data` instala Docker y levanta la API |
| `aws_iam_role` + `aws_iam_instance_profile` | Permiso de la EC2 para subir fotos a `reports/` del bucket  |
| `aws_s3_bucket.photos`                    | Bucket de las fotos, con lectura publica solo de `reports/*` |

El `user_data` de la EC2 (`templates/user_data.sh.tftpl`):

1. Crea 1 GB de swap.
2. Instala Docker y Docker Compose.
3. Actualiza el hostname de No-IP con la IP publica de la instancia, usando la API
   `https://dynupdate.no-ip.com/nic/update`. Lo repite en cada reinicio.
4. Escribe `~/aguafix/compose.yaml` (API de Docker Hub + PostgreSQL) y `~/aguafix/.env`.
5. Ejecuta `docker compose pull` y `docker compose up -d`.

La API queda en `http://<hostname-noip>/`: el puerto 80 de la EC2 va al 3000 del contenedor.
PostgreSQL no se expone fuera del servidor.

La EC2 no guarda llaves de AWS: la API sube las fotos con el rol IAM de la instancia (IMDSv2
con hop limit 2 para que el contenedor alcance las credenciales).

## Archivos

| Archivo                        | Contenido                                          |
| ------------------------------ | -------------------------------------------------- |
| `versions.tf`                  | Terraform y el provider de AWS                     |
| `variables.tf`                 | Variables; las credenciales son `sensitive`        |
| `main.tf`                      | Security group, key pair, rol IAM y EC2            |
| `s3.tf`                        | Bucket y su politica de lectura publica            |
| `outputs.tf`                   | IP, URL con el dominio y comando SSH               |
| `templates/user_data.sh.tftpl` | Script de arranque de la EC2                       |
| `terraform.tfvars.example`     | Ejemplo de valores; el real no se sube a Git       |

## Requisitos

- Terraform >= 1.6 y la CLI de AWS configurada con un usuario que pueda crear EC2, IAM y S3
  (`aws configure`). Terraform toma las credenciales de la CLI; no van en ningun archivo `.tf`.
- Un hostname creado una vez en [noip.com](https://www.noip.com), por ejemplo
  `aguafix-tu-nombre.ddns.net`.
- Una llave SSH para el despliegue:

  ```bash
  ssh-keygen -t ed25519 -N "" -C "aguafix-deploy" -f ~/.ssh/aguafix_ed25519
  ```

## Uso

```bash
cp terraform.tfvars.example terraform.tfvars   # y llena los valores
terraform init
terraform apply
```

Al terminar muestra los outputs:

```
api_url     = "http://aguafix-tu-nombre.ddns.net/"
api_url_ip  = "http://3.x.x.x/"
bucket_name = "aguafix-fotos-tu-nombre"
public_ip   = "3.x.x.x"
ssh_command = "ssh -i ~/.ssh/aguafix_ed25519 ubuntu@3.x.x.x"
```

La EC2 tarda unos 2 o 3 minutos en instalar Docker y levantar la API despues del `apply`.

Para borrar todo:

```bash
terraform destroy
```

## Secrets del repositorio de la API

El workflow de la API despliega por SSH. En
`511-WaterReportsApi > Settings > Secrets and variables > Actions`:

| Secret        | Valor                                                      |
| ------------- | ---------------------------------------------------------- |
| `EC2_HOST`    | El hostname de No-IP (no cambia entre `apply` y `destroy`) |
| `EC2_SSH_KEY` | Contenido de `~/.ssh/aguafix_ed25519` (la llave privada)   |

Con la CLI de GitHub:

```bash
gh secret set EC2_HOST -R LeoGoMa/511-WaterReportsApi --body "aguafix-tu-nombre.ddns.net"
gh secret set EC2_SSH_KEY -R LeoGoMa/511-WaterReportsApi < ~/.ssh/aguafix_ed25519
```

## Diagnostico en el servidor

```bash
sudo tail -50 /var/log/cloud-init-output.log   # instalacion y arranque
sudo cat /var/log/aguafix-noip.log             # respuesta de No-IP (good / nochg / badauth)
cd ~/aguafix && docker compose ps && docker compose logs api --tail 50
```

## Lo que no se sube a Git

`terraform.tfvars`, `*.tfstate`, `.terraform/` y las llaves SSH estan en `.gitignore`.

## Costos estimados

Mientras la infraestructura esta encendida (precios de us-east-2):

| Recurso            | Costo aproximado                         |
| ------------------ | ---------------------------------------- |
| EC2 `t3.micro`     | ~0.01 USD por hora (gratis en free tier) |
| IP publica IPv4    | ~0.005 USD por hora                      |
| Disco gp3 de 20 GB | ~1.6 USD al mes                          |
| Bucket S3          | centavos con pocas fotos                 |

Por eso se ejecuta `terraform destroy` al terminar: sin recursos no hay cobro.
