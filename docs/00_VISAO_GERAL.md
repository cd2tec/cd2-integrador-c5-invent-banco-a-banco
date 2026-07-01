# Visão geral do integrador CD2

## O que é

Camada técnica Oracle (**owner `CD2`**) que integra o **Consinco (C5)** com o **Invent WMS (Velox)** via **database link**, sem middleware externo. Responsável por:

1. **ENVIO** — volumes separados no C5 → `GPT_INTEGRA_REMESSA@INVENT`
2. **RETORNO** — montagem/palete no Invent → fechamento no C5 (`MLO_MONTAGEMSORTER`, paletes, carregamento)
3. **Monitoramento** — views e tabela de eventos para KPI, fila e pendências

## Camadas

```
┌─────────────────────────────────────────────────────────────┐
│  CONSINCO (C5)                                              │
│  MLO_INTEGRACAOSORTER, MLO_MONTAGEMSORTER, MLO_CARGA*, etc. │
└───────────────────────────┬─────────────────────────────────┘
                            │ grants SELECT/INSERT/UPDATE
┌───────────────────────────▼─────────────────────────────────┐
│  CD2 (integrador)                                           │
│  Views DDV_*  │  Tabelas DD_SORTER_*  │  Procedures DD_PRC_* │
│  Jobs DD_JOB_BATCH_ENVIO_W*  │  DD_JOB_BATCH_RETORNO_W*       │
└───────────────────────────┬─────────────────────────────────┘
                            │ dblink @INVENT
┌───────────────────────────▼─────────────────────────────────┐
│  INVENT (Velox)                                             │
│  GPT_INTEGRA_REMESSA, GPT_RETORNO_MONTAGEM_PALETES, ...     │
└─────────────────────────────────────────────────────────────┘
```

## Produção atual (01/07/2026)

| Operação | Workers | Procedure principal | Intervalo |
|----------|---------|---------------------|-----------|
| Envio | 3 (W1–W3) | `DD_PRC_BATCH_ENVIO_WORKER` → `DD_PRC_ENVIA_C5_INVENT` | 5 min |
| Retorno | 6 (W1–W6) | `DD_PRC_BATCH_RETORNO_V3` → `DD_PRC_FECHA_C5_ETIQUETA` | 5 min |

## Documentos nesta pasta

| Arquivo | Conteúdo |
|---------|----------|
| [01_ARQUITETURA_E_FLUXOS.md](01_ARQUITETURA_E_FLUXOS.md) | Fluxos envio e retorno detalhados |
| [02_CATALOGO_OBJETOS.md](02_CATALOGO_OBJETOS.md) | Lista de todos os objetos CD2 |
| [03_IMPLANTACAO_NOVO_CLIENTE.md](03_IMPLANTACAO_NOVO_CLIENTE.md) | Roteiro passo a passo |
| [04_OPERACAO_E_MONITORAMENTO.md](04_OPERACAO_E_MONITORAMENTO.md) | Jobs, filas, throughput |
| [05_VALIDACAO_E_TROUBLESHOOTING.md](05_VALIDACAO_E_TROUBLESHOOTING.md) | Protocolo de checagem |
| [06_TABELAS_E_OBJETOS_EXTERNOS.md](06_TABELAS_E_OBJETOS_EXTERNOS.md) | Tabelas C5, Invent e CD2 |
| [07_GOVERNANCA_GIT.md](07_GOVERNANCA_GIT.md) | Sincronização banco → Git (obrigatório após deploy) |
