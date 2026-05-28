# windows ad terraform

windows server 2022 + active directory provisionado com terraform na aws.

## estrutura

```
.
├── .github/workflows/        # github actions (validate, apply, destroy)
├── environments/dev/         # ambiente dev
│   ├── provider.tf           # providers + backend s3
│   ├── main.tf               # orquestracao dos modulos
│   └── outputs.tf            # ips, comandos uteis
├── modules/
│   ├── windows-server/       # ec2 windows server 2022
│   ├── s3/                   # bucket com kms e versionamento
│   └── security-group/       # sg liberando rdp (3389)
├── scripts/
│   ├── setup.sh              # prepara o ambiente (cria bucket state)
│   └── configure-ad.ps1      # automatiza ad, gpo, tasks
├── policies/
│   └── terraform.rego        # opa policy para seguranca
└── README.md
```

## pre-requisitos

- aws cli configurado (aws configure)
- terraform >= 1.9

## deploy rapido

```bash
# 1. preparar ambiente (cria bucket do state se nao existir)
./scripts/setup.sh

# 2. criar key pair para acessar o windows
aws ec2 create-key-pair --key-name windows-ad-key --query 'KeyMaterial' --output text > windows-ad-key.pem
chmod 400 windows-ad-key.pem

# 3. deploy
cd environments/dev
terraform init
terraform apply
```

## acessar via rdp

```bash
# decryptar senha
aws ec2 get-password-data --instance-id <id-da-ec2> --priv-launch-key ../../windows-ad-key.pem

# conectar (windows: mstsc / mac: microsoft remote desktop)
ip: <ip-publico>
usuario: Administrator
senha: <senha decryptada>
```

## seguranca

- s3 com block public access, kms encryption e versionamento
- security group com prevent_destroy
- github actions com checkov + tfsec nos pushes
- opa policy para bloquear sg com 0.0.0.0/0 (produção)

## github actions

| workflow | acao | descricao |
|----------|------|-----------|
| validate | push/pr | terraform fmt + validate + plan + checkov + tfsec |
| apply    | manual via github | sobe a infra |
| destroy  | manual via github | derruba a infra |
