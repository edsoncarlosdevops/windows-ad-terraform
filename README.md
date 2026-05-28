# windows ad terraform

windows server 2022 + active directory provisionado com terraform na aws.

## deploy

```bash
# 1. bootstrap: cria o bucket para o state remoto
cd environments/bootstrap
terraform init && terraform apply

# 2. deploy: sobe a infra usando o state remoto
cd ../dev
terraform init && terraform apply
```

## apos o deploy

```bash
# decryptar senha do administrator
aws ec2 get-password-data --instance-id <id> --priv-launch-key windows-ad-key.pem

# conectar via rdp
mstsc /v:<ip_publico>
```

usuario: administrator

## destroy

```bash
cd environments/dev
terraform destroy
```

## estrutura

```
.
├── .github/workflows/       # github actions
├── environments/
│   ├── bootstrap/           # cria o bucket do state (passo 0)
│   └── dev/                 # infra principal
├── modules/
│   ├── windows-server/      # ec2 windows server 2022
│   ├── s3/                  # bucket com kms e versionamento
│   └── security-group/      # sg para rdp (3389)
├── scripts/
│   └── configure-ad.ps1     # automatiza ad, gpo e tasks
├── policies/
│   └── terraform.rego       # opa policy
└── README.md
```

## seguranca

- s3 com block public access, kms encryption, versionamento e lifecycle
- security group com prevent_destroy
- github actions com checkov + tfsec
- senha do admin gerada aleatoriamente
