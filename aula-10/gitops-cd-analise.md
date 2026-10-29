# Análise: GitOps (Terraform) e Pipeline CD — TechNova

**Aluno:** Gabriel de Souza Oliveira · **RA:** 6325262 · **Aula 10**

## 1. Fluxo GitOps: por que plan no PR e apply no merge

GitOps trata o Git como fonte da verdade da infraestrutura. Toda mudança passa pelo mesmo caminho de uma mudança de código:

1. Abre-se um **PR** alterando arquivos `.tf`.
2. O workflow `terraform-plan.yml` roda `fmt`, `init`, `validate` e `plan`, e posta o resultado como **comentário no PR** (atualizado a cada novo push, sem duplicar).
3. O revisor lê o plan (o "diff de infraestrutura") e responde: o que será criado, alterado ou **destruído**?
4. Com o PR aprovado e mergeado na `main`, o workflow `terraform-apply.yml` roda `terraform apply -auto-approve`.

**Por que assim:**
- O **plan no PR** dá visibilidade *antes* de qualquer mudança real, permitindo revisão formal (o Slack não é aprovação).
- O **apply no merge** faz do merge a aprovação: só o que foi revisado vai para a AWS.
- Ninguém aplica pelo laptop: sem credenciais locais, sem divergência entre Git e AWS.
- O `git log` vira trilha de auditoria; o rollback de infra é um `git revert`.
- Se o plan falha, o workflow falha e o PR não deve ser mergeado.

## 2. Autenticação no Learner Lab e OIDC em produção

**No Lab:** o pipeline usa as 3 credenciais temporárias da sessão (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`) guardadas como **GitHub Secrets** e entregues ao `aws-actions/configure-aws-credentials@v4`. Os secrets são criptografados e mascarados nos logs. Limitação: **expiram quando a sessão do Lab fecha**, então precisam ser atualizados a cada sessão (erro típico: `ExpiredToken`).

**Em produção:** o ideal é **OIDC + role IAM**. O GitHub emite um token de curta duração, a AWS valida e o workflow assume uma role (`role-to-assume`). Não há nenhuma chave armazenada, o token vale minutos e a permissão é restrita por repositório/branch.

**Por que o Lab não permite:** OIDC exige criar um *Identity Provider* e uma *role IAM* com trust policy, e ambos são bloqueados no AWS Academy Learner Lab. A diferença para produção não é de conceito, é de permissão disponível.

## 3. Estratégia Recreate

Para o container antigo, remove e sobe o novo (`docker stop` → `rm` → `pull` → `run`), com login no ECR antes do pull.

| Prós | Contras |
|------|---------|
| Simples, sem infraestrutura extra | Downtime de alguns segundos a cada deploy |
| Barata (uma única EC2) | Sem versão antiga rodando em paralelo para reverter instantaneamente |
| Fácil de entender e depurar | Se a versão nova falhar, há indisponibilidade até o rollback |

**Quando usar:** startups, ambientes de dev/homologação, aplicações que toleram uma breve indisponibilidade. Para zero downtime, as próximas aulas apresentam Blue-Green e Canary.

## 4. Continuous Delivery vs Continuous Deployment

| | Continuous Delivery | Continuous Deployment |
|---|---|---|
| Ideia | Sempre pronto para ir a produção | Todo commit aprovado nos testes vai a produção |
| Aprovação | Botão/aprovação manual antes do deploy | Nenhuma, totalmente automático |
| Indicado para | Compliance, releases planejadas | SaaS e iteração rápida |

Este pipeline é **Continuous Deployment**: todo push na `main` que passa por lint e testes é construído e implantado, com health check no final. Uma evolução seria usar *GitHub Environments* com aprovação para virar Continuous Delivery.

## 5. Rollback

As imagens são publicadas no ECR com **tag SHA do commit** (e `latest`). Reverter é implantar uma tag SHA anterior. O procedimento completo, incluindo o login no ECR antes do pull, está em [`docs/runbook-rollback.md`](docs/runbook-rollback.md). Rastreabilidade: commit no Git ↔ imagem no ECR ↔ container na EC2 (variável `GIT_SHA`).

## 6. Limitações e melhorias

- Credenciais do Lab expiram: precisam ser renovadas manualmente a cada sessão.
- SSH aberto para `0.0.0.0/0` (runners do GitHub têm IP variável). Em produção: restringir aos ranges publicados em `api.github.com/meta`, ou usar SSM em vez de SSH.
- As credenciais de sessão são enviadas à EC2 durante o deploy para o login no ECR; em produção a EC2 usaria um *instance profile*.
- Recreate causa downtime; evoluir para Blue-Green/Canary.
- `apply` automático sem aprovação extra para `destroy`; melhoria: detectar destruição no plan e exigir aprovação (GitHub Environment).
- Sem notificação de deploy (Slack/Discord) e sem estimativa de custo (Infracost).
- Rollback é manual; poderia ser automático quando o health check falha.
