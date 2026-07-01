# Governança Git — pacote CD2 integrador

## Princípio

O que está **compilado em produção** no owner `CD2` deve estar **versionado** neste repositório. O GitHub é o espelho auditável do DDL; o banco é a instância em execução.

**URL:** https://github.com/cd2tec/cd2-integrador-c5-invent-banco-a-banco

## Quando sincronizar

| Situação | Ação no repositório |
|----------|---------------------|
| `CREATE OR REPLACE` em procedure/package/view | Atualizar arquivo numerado correspondente |
| Novo índice ou tabela CD2 | Atualizar ou re-exportar |
| Mudança em job scheduler (workers, intervalo) | Atualizar `044_JOBS_PROD_ENVIO_3W_RETORNO_6W.sql` |
| Novo grant Consinco → CD2 | Atualizar `045_GRANTS_CONSINCO_PARA_CD2.sql` |
| Reprocesso DML pontual (etiquetas, eventos) | **Não** exige DDL no pacote; documentar no runbook SORTER se relevante |

## Fluxo padrão (agente / deploy)

```
Diff + aprovação → aplicar no Oracle → sincronizar esta pasta → git diff → commit/push (se autorizado)
```

Regras Cursor no projeto SORTER:

- `.cursor/rules/oracle-db-no-change-without-diff.mdc` — antes do banco
- `.cursor/rules/cd2-ddl-git-sync.mdc` — depois do banco

## Como atualizar os arquivos

### Objeto único

1. Ler `ALL_SOURCE` (ou metadados do job) no ambiente correto (PROD).
2. Colar no `.sql` listado em `docs/02_CATALOGO_OBJETOS.md` / `_export_manifest.json`.
3. Preservar cabeçalho de export no topo do arquivo.

### Re-export completo

No workspace SORTER (fora deste repo):

```bash
node monitor_app/backend/export_cd2_integrador.mjs
```

Sobrescreve os scripts a partir do banco PROD. Revisar diff antes de commit.

## Git

Este diretório é um repositório Git **independente** do projeto SORTER:

```bash
cd cd2-integrador-c5-invent-banco-a-banco
git status
git add -A
git commit -m "sync: <objeto ou resumo do fix>"
git push origin main
```

**Escopo de commit/push:** somente arquivos **dentro** de `cd2-integrador-c5-invent-banco-a-banco/`. Alterações na raiz SORTER (`AGENTE_IA_*`, `.cursor/rules/`, `monitor_app/`, `execucao_projeto_sorter/`, etc.) **não** entram neste repositório.

## O que não versionar aqui

- Credenciais ou connection strings
- Scripts operacionais do `monitor_app/`
- Export HML (`cd2_full_export_from_hml_*`) — ambiente separado
