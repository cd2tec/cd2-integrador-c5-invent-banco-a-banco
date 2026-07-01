# CD2 — Integrador Consinco × Invent (banco a banco)

Pacote **sincronizado com o banco remoto** em **01/07/2026**.  
Contém DDL completo do owner `CD2`: tabelas, views, procedures, package, jobs de produção e grants Consinco.

**Configuração de produção validada:**
- **Envio:** 3 workers (`DD_JOB_BATCH_ENVIO_W1` … `W3`)
- **Retorno:** 6 workers GPT-first (`DD_JOB_BATCH_RETORNO_W1` … `W6`, procedure `DD_PRC_BATCH_RETORNO_V3`)

## Estrutura

| Faixa | Conteúdo |
|-------|----------|
| `001`–`002` | Sequences |
| `003`–`006` | Tabelas CD2 |
| `007`–`016` | Índices |
| `017`–`029` | Views |
| `030`–`031` | Package `DD_PKG_FECHA_CACHE` |
| `032`–`043` | Procedures |
| `044` | Scheduler jobs (prod) |
| `045` | Grants Consinco → CD2 |
| `docs/` | Manual técnico completo |

## Ordem de implantação

1. Pré-requisitos: schema CD2, DB link `@INVENT`, grants (`045`)
2. Executar scripts `001` → `043` em ordem numérica (SQL\*Plus ou `@`)
3. Jobs `044` (ou criar manualmente no Scheduler)
4. Validar compilação: `SELECT object_name, status FROM user_objects WHERE status='INVALID'`
5. Habilitar workers de envio e retorno

Detalhes: [`docs/03_IMPLANTACAO_NOVO_CLIENTE.md`](docs/03_IMPLANTACAO_NOVO_CLIENTE.md)

## Manifest

Lista completa de arquivos exportados: `_export_manifest.json`

## Script de re-export

Para atualizar a partir do banco: `monitor_app/backend/export_cd2_integrador.mjs`
