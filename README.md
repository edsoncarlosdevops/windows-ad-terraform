# windows ad terraform

windows server 2022 + active directory provisionado com terraform na aws.

## quick start

```bash
git clone https://github.com/edsoncarlosdevops/windows-ad-terraform.git
cd windows-ad-terraform

# unico comando para subir tudo
./deploy.sh
```

## apos o deploy

o script ja mostra os comandos para conectar via rdp:

```bash
# decryptar senha do administrator
aws ec2 get-password-data --instance-id <id> --priv-launch-key windows-ad-key.pem

# conectar
mstsc /v:<ip_publico>
```

usuario: administrator

## destroy

```bash
terraform destroy
```

(o bucket do state continua existindo para preservar o state)

## estrutura

```
.
├── .github/workflows/     # github actions (validate, apply, destroy)
├── environments/dev/      # configuracao do ambiente
│   ├── provider.tf        # backend s3 + providers
│   ├── main.tf            # orquestracao dos modulos
│   └── outputs.tf         # ips e comandos de acesso
├── modules/
│   ├── windows-server/    # ec2 windows server 2022
│   ├── s3/                # bucket com kms e versionamento
│   └── security-group/    # sg para rdp (3389)
├── scripts/
│   └── configure-ad.ps1   # automatiza ad, gpo e tasks
├── policies/
│   └── terraform.rego     # opa policy para seguranca
├── deploy.sh              # deploy completo (1 comando)
└── README.md
```

## seguranca

- s3 com block public access, kms encryption, versionamento e lifecycle
- security group com prevent_destroy
- github actions com checkov + tfsec nos pushes
- senha do admin gerada aleatoriamente

## github actions

| workflow | acionamento | descricao |
|----------|-------------|-----------|
| validate | push / pr | terraform fmt + validate + checkov + tfsec |
| apply | manual | sobe a infra |
| destroy | manual | derruba a infra |
