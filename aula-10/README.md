# Aula 10 — Terraform Automatizado e CD Pipelines (TechNova)

Fluxo GitOps para Terraform (plan no PR, apply no merge) e pipeline CD (lint → test → build → push no ECR → deploy na EC2 → health check), no AWS Academy Learner Lab (`us-east-1`).

## Estrutura

```
.github/workflows/            # (raiz do repositório — é onde o GitHub executa)
├── terraform-plan.yml        # plan automático em PRs + comentário
├── terraform-apply.yml       # apply automático no merge na main
└── cd.yml                    # lint → test → build → push (ECR) → deploy → health check
aula-10/
├── .github/workflows/        # cópia dos workflows (referência da estrutura do TF)
├── terraform/                # provider.tf, variables.tf, main.tf, outputs.tf (ECR + SG + EC2)
├── technova-api/             # API Node/Express, testes e Dockerfile multi-stage
├── docs/runbook-rollback.md
├── gitops-cd-analise.md
└── screenshots/              # evidências (4 prints)
```

> Os workflows que o GitHub executa são os da **raiz** (`.github/workflows/`). A cópia em `aula-10/.github/workflows/` é só para documentação.

## Como reproduzir

1. **Secrets** (Settings → Secrets and variables → Actions):

   | Secret | Valor |
   |---|---|
   | `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN` | AWS Details do Learner Lab (expiram a cada sessão) |
   | `TF_STATE_BUCKET` | Bucket S3 do state remoto (Aula 08) |
   | `EC2_HOST` | IP público da EC2 (output `ec2_public_ip`) |
   | `EC2_USERNAME` | `ubuntu` |
   | `EC2_SSH_KEY` | Conteúdo completo da chave `.pem` (vockey) |

2. **Infra (GitOps):** abra um PR alterando um `.tf` → veja o plan no comentário → faça o merge → o apply roda. Isso cria o ECR, o Security Group e a EC2.
3. **Deploy (CD):** com a infra criada, qualquer push na `main` em `aula-10/technova-api/**` dispara o `cd.yml`.
4. **Evidências:** salve os 4 prints em `screenshots/` (`plan-pr-comment.png`, `apply-success.png`, `cd-pipeline-green.png`, `health-check-pass.png`).

## Observações
- Autenticação no Lab usa credenciais de sessão; em produção seria OIDC + role IAM (ver `gitops-cd-analise.md`).
- O Terraform espera o key pair `vockey` do Learner Lab (variável `key_name`).
