# Catálogo de objetos CD2

Export validado em **01/07/2026**. Arquivo SQL correspondente entre parênteses.

## Sequences

| Objeto | Arquivo |
|--------|---------|
| `SQ_DD_SORTER_EVENTO_CTRL` | 001 |
| `SQ_DD_SORTER_VINCULO_RETORNO_ETQ` | 002 |

## Tabelas

| Objeto | Descrição | Arquivo |
|--------|-----------|---------|
| `DD_SORTER_BATCH_CARGA_CTRL` | Fila de cargas (PENDENTE/PROCESSANDO/CONCLUIDA) | 003 |
| `DD_SORTER_EVENTO_CTRL` | Log de eventos envio/retorno/batch | 004 |
| `DD_SORTER_GPT_RETORNO_FILA` | GTT para staging retorno GPT-first | 005 |
| `DD_SORTER_VINCULO_RETORNO_ETQ` | Vínculo etiqueta ↔ master/palete retorno | 006 |

## Índices (007–016)

| Índice | Tabela |
|--------|--------|
| `IX_DD_SORTER_BATCH_CARGA_ST` | BATCH_CARGA_CTRL |
| `PK_DD_SORTER_BATCH_CARGA` | BATCH_CARGA_CTRL |
| `IX_DD_SORTER_EVT_CAPT` | EVENTO_CTRL |
| `IX_DD_SORTER_EVT_ETQ` | EVENTO_CTRL |
| `IX_DD_SORTER_EVT_ETQ_ORG_ST` | EVENTO_CTRL |
| `PK_DD_SORTER_EVENTO_CTRL` | EVENTO_CTRL |
| `UK_DD_SORTER_EVT_HASH` | EVENTO_CTRL |
| `PK_DD_SORTER_VINCULO_RET` | VINCULO_RETORNO_ETQ |
| `UK_DD_SORTER_VINCULO_ETQ` | VINCULO_RETORNO_ETQ |
| `UK_DD_SORTER_VINCULO_RET` | VINCULO_RETORNO_ETQ |

## Views (017–029)

| View | Uso principal |
|------|----------------|
| `DDV_SORTER_CORRELACAO` | Correlação etiqueta ↔ carga (base) |
| `DDV_SORTER_CORRELACAO_ENRIQ` | + produto, embalagem, destino, CODACESSO |
| `DDV_SORTER_FILA_ENVIO` | Fila de envio |
| `DDV_SORTER_FILA_ENVIO_ENRIQ` | Fila enriquecida |
| `DDV_SORTER_STATUS_INVENT` | Status Invent por etiqueta |
| `DDV_SORTER_RETORNO_C5` | Dados retorno C5 |
| `DDV_SORTER_RETORNO_C5_ENRIQ` | Retorno enriquecido |
| `DDV_SORTER_PENDENCIAS` | Pendências operacionais |
| `DDV_SORTER_BACKLOG_ATUAL_HML` | Backlog monitoramento |
| `DDV_SORTER_MONITOR_HML` | Dashboard monitor |
| `DDV_SORTER_KPI_DIARIO_HML` | KPI diário |
| `DDV_SORTER_SLA_HML` | SLA |
| `DDV_SORTER_ULTIMO_STATUS_HML` | Último status por etiqueta |

## Package

| Objeto | Arquivo |
|--------|---------|
| `DD_PKG_FECHA_CACHE` (spec) | 030 |
| `DD_PKG_FECHA_CACHE` (body) | 031 |

Cache em memória para `DD_PRC_FECHA_C5_ETIQUETA` (dados de carga/produto).

## Procedures (032–043)

| Procedure | Papel |
|-----------|-------|
| `DD_PRC_CAPTURA_STATUS_INVENT` | Captura status GPT → eventos |
| `DD_PRC_RECONCILIA_ETIQUETA` | Reconciliação etiqueta |
| `DD_PRC_ENVIA_C5_INVENT` | **Envio** — leva → GPT_INTEGRA_REMESSA |
| `DD_PRC_FECHA_C5_ETIQUETA` | **Fechamento** — retorno C5 |
| `DD_PRC_BATCH_CARGA_SYNC` | Sincroniza fila de cargas |
| `DD_PRC_BATCH_ENVIO` | Loop envio por carga |
| `DD_PRC_BATCH_ENVIO_SHARD` | Envio shard (legado) |
| `DD_PRC_BATCH_ENVIO_WORKER` | Worker envio com claim |
| `DD_PRC_BATCH_HML` | Batch HML completo |
| `DD_PRC_BATCH_RETORNO` | Retorno V1 |
| `DD_PRC_BATCH_RETORNO_V2` | Retorno V2 |
| `DD_PRC_BATCH_RETORNO_V3` | **Retorno produção** GPT-first |

## Jobs (044)

| Job | Ativo prod | Ação |
|-----|------------|------|
| `DD_JOB_BATCH_ENVIO_W1` | SIM | `DD_PRC_BATCH_ENVIO_WORKER('W1', 200)` |
| `DD_JOB_BATCH_ENVIO_W2` | SIM | `DD_PRC_BATCH_ENVIO_WORKER('W2', 200)` |
| `DD_JOB_BATCH_ENVIO_W3` | SIM | `DD_PRC_BATCH_ENVIO_WORKER('W3', 200)` |
| `DD_JOB_BATCH_RETORNO_W1`–`W6` | SIM | `DD_PRC_BATCH_RETORNO_V3(100, worker, 6)` |

Jobs legados desabilitados em prod: `DD_JOB_BATCH_ENVIO`, `DD_JOB_BATCH_RETORNO`, `DD_JOB_BATCH_HML`, shards 115178.

## Grants (045)

Executar como **CONSINCO** — ver `045_GRANTS_CONSINCO_PARA_CD2.sql`.
