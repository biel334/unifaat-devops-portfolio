# Runbook — Rollback da TechNova API

Cada deploy usa uma imagem com **tag SHA do commit** no ECR. O rollback consiste em subir uma tag anterior.

## Quando usar
- Health check falhou após um deploy, ou a versão nova apresenta erro em produção.

## Pré-requisitos
- Credenciais da sessão do Lab válidas (se `ExpiredToken`, reabra o Learner Lab e atualize os secrets).
- Chave `.pem` e IP público da EC2.

## Passo a passo

**1. Descobrir a tag anterior boa** (no seu computador, com credenciais do Lab configuradas):
```bash
aws ecr describe-images --repository-name technova-api --region us-east-1 \
  --query 'sort_by(imageDetails,&imagePushedAt)[*].[imageTags,imagePushedAt]' --output table
```
Ou use o SHA de um commit anterior bem-sucedido (aba Actions / `git log`).

**2. Conectar na EC2:**
```bash
ssh -i ~/.ssh/SUA-CHAVE.pem ubuntu@EC2_HOST
```

**3. Fazer login no ECR ANTES do pull** (token expira em ~12h):
```bash
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_SESSION_TOKEN=...
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGISTRY="${ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com"
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin "$REGISTRY"
```

**4. Subir a versão anterior (Recreate):**
```bash
IMAGE="$REGISTRY/technova-api:SHA_ANTERIOR"
docker pull "$IMAGE"
docker stop technova-api || true
docker rm technova-api || true
docker run -d --name technova-api --restart unless-stopped -p 3000:3000 -e GIT_SHA=SHA_ANTERIOR "$IMAGE"
```

**5. Validar:**
```bash
curl -fsS http://localhost:3000/health
docker ps --filter name=technova-api
```

## Alternativa via Git (rollback pelo pipeline)
```bash
git revert <SHA_DO_COMMIT_COM_PROBLEMA>
git push origin main
```
O `cd.yml` roda de novo, gera nova imagem do código revertido e faz o deploy com health check.

## Rollback de infraestrutura
`git revert` do commit com a mudança no Terraform, PR, revisão do plan e merge. O `terraform-apply.yml` aplica o estado anterior.

## Erros comuns
| Erro | Causa | Solução |
|------|-------|---------|
| `ExpiredToken` / `token has expired` | Sessão do Lab expirou | Reabrir o Lab e atualizar os 3 secrets |
| `no basic auth credentials` no pull | Faltou o login no ECR | Refazer o passo 3 antes do `docker pull` |
| Health check não responde | Porta 3000 fechada no Security Group | Liberar a porta 3000 |
