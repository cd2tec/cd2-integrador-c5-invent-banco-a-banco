# Operação e monitoramento

## Jobs ativos (produção)

| Job | Intervalo | Procedure |
|-----|-----------|-----------|
| `DD_JOB_BATCH_ENVIO_W1`–`W3` | 5 min | `DD_PRC_BATCH_ENVIO_WORKER` |
| `DD_JOB_BATCH_RETORNO_W1`–`W6` | 5 min | `DD_PRC_BATCH_RETORNO_V3` |

## Fila de envio

```sql
SELECT status, COUNT(*) cargas, SUM(vols_elegiveis) vols
  FROM cd2.dd_sorter_batch_carga_ctrl
 GROUP BY status;
```

| STATUS | Significado |
|--------|-------------|
| PENDENTE | Aguardando worker |
| PROCESSANDO | Worker ativo nesta carga |
| CONCLUIDA | Sem volumes elegíveis (reativa quando chegam novos) |

## Throughput envio (etq/min)

```sql
SELECT COUNT(DISTINCT codbarraetq) etq,
       ROUND(COUNT(DISTINCT codbarraetq) / 15, 1) etq_min
  FROM cd2.dd_sorter_evento_ctrl
 WHERE origem = 'ENVIO' AND status_origem = 'ENVIADO_INVENT'
   AND UPPER(obs) LIKE '%INTEGRACAO TOTAL DESTINO%'
   AND dta_captura >= SYSDATE - 15/1440;
```

Referência produção: **10–16 etq/min** (3 workers), com picos ao fechar levas.

## Throughput retorno

```sql
SELECT COUNT(DISTINCT codbarraetq) etq,
       ROUND(COUNT(DISTINCT codbarraetq) / 15, 1) etq_min
  FROM cd2.dd_sorter_evento_ctrl
 WHERE origem = 'RETORNO'
   AND dta_captura >= SYSDATE - 15/1440;
```

Referência pós-otimização V3: **~10–12 etq/min** (6 workers).

## Views de monitoramento

| View | Uso |
|------|-----|
| `DDV_SORTER_MONITOR_HML` | Painel operacional |
| `DDV_SORTER_PENDENCIAS` | Itens pendentes |
| `DDV_SORTER_BACKLOG_ATUAL_HML` | Backlog retorno |
| `DDV_SORTER_KPI_DIARIO_HML` | KPIs diários |

## Estados de evento ENVIO (`DD_SORTER_EVENTO_CTRL`)

| STATUS_ORIGEM | Significado |
|---------------|-------------|
| `ENVIO_BUFFER` | Aguardando fechar leva |
| `ENVIADO_INVENT` + OBS `INTEGRACAO TOTAL DESTINO` | **Enviado de verdade** (GPT) |
| `BLOQUEIO_SEM_CODACESSO` | Sem CODACESSO MAP — não envia |
| `ERRO_ENVIO` | Exceção — ver OBS |
| `ENVIADO_INVENT_OBSOLETO` | Histórico bug antigo — não bloqueia |

## Reprocessamento manual (exceção)

Normalmente o batch resolve sozinho. Para forçar uma carga:

```sql
BEGIN CD2.DD_PRC_BATCH_CARGA_SYNC; END;
BEGIN CD2.DD_PRC_BATCH_ENVIO(P_NROCARGA => <carga>, P_LIMIT => 200); END;
```

Para etiqueta individual:

```sql
BEGIN CD2.DD_PRC_ENVIA_C5_INVENT(P_CODBARRAETQ => '<etq>'); END;
```

## Neutralizar evento falso (bug histórico JA ENVIADO)

Somente se volumes ficaram presos **antes** da correção de código:

```sql
UPDATE cd2.dd_sorter_evento_ctrl
   SET status_origem = 'ENVIADO_INVENT_OBSOLETO',
       obs = '[REPROC] ' || obs
 WHERE id_evento IN (<lista explicita>);
-- Depois: SYNC + batch, ou chamar DD_PRC_ENVIA_C5_INVENT
```
