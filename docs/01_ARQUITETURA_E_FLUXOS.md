# Arquitetura e fluxos

## Fluxo de ENVIO (C5 → Invent)

```
Etiqueta em MLO_INTEGRACAOSORTER (separada / recebimento)
        │
        ▼
DD_PRC_BATCH_CARGA_SYNC
   Conta volumes elegíveis (sem ENVIADO_INVENT)
   Reativa carga CONCLUIDA → PENDENTE quando chegam volumes novos
        │
        ▼
DD_JOB_BATCH_ENVIO_W1 | W2 | W3  (cada 5 min)
        │
        ▼
DD_PRC_BATCH_ENVIO_WORKER
   Claim atômico de 1 carga em DD_SORTER_BATCH_CARGA_CTRL
        │
        ▼
DD_PRC_BATCH_ENVIO  (até P_LIMIT=200 etiquetas/ciclo)
        │
        ▼
DD_PRC_ENVIA_C5_INVENT  (por etiqueta / por leva de destino)
   • Agrupa por destino (ETIQUETAORIGEM + SEQPRODUTO + TIPESPECIE)
   • Fecha levas de até 100 volumes (C_LEVA_MAX_VOLUMES)
   • SEQLOTE leva 1 = ETIQUETAORIGEM; leva 2+ = ETIQUETAORIGEM*1000+N
   • INSERT/UPDATE em GPT_INTEGRA_REMESSA@INVENT
   • Evento DD_SORTER_EVENTO_CTRL: ENVIO_BUFFER → ENVIADO_INVENT (INTEGRACAO TOTAL)
        │
        ▼
Invent induz volumes a partir da GPT
```

### Envio incremental (volumes adicionados depois)

Quando o time adiciona volumes à mesma carga horas depois:
- Volumes novos **não têm** `ENVIADO_INVENT`
- `DD_PRC_BATCH_CARGA_SYNC` detecta `VOLS_ELEGIVEIS > 0` e reativa a carga
- `DD_PRC_ENVIA_C5_INVENT` cria **nova leva** (SEQLOTE `...002`, `...003`, etc.)
- **Não bloqueia** destino já integrado (código atual não tem "JA ENVIADO INVENT")

---

## Fluxo de RETORNO (Invent → C5)

```
GPT_RETORNO_MONTAGEM_PALETES@INVENT  (Invent grava retorno)
        │
        ▼
DD_JOB_BATCH_RETORNO_W1 … W6  (cada 5 min, GPT-first V3)
        │
        ▼
DD_PRC_BATCH_RETORNO_V3
   • Popula GTT DD_SORTER_GPT_RETORNO_FILA (evita dblink em SQL estático)
   • Particiona por worker: MOD(ORA_HASH(codbarras), 6) = worker_id
   • Cruza com DDV_SORTER_CORRELACAO / elegibilidade
   • Chama DD_PRC_FECHA_C5_ETIQUETA por etiqueta
        │
        ▼
DD_PRC_FECHA_C5_ETIQUETA
   • Usa cache DD_PKG_FECHA_CACHE (performance)
   • MERGE/INSERT em MLO_MONTAGEMSORTER, paletes, carregamento
   • Grava DD_SORTER_VINCULO_RETORNO_ETQ
   • Eventos em DD_SORTER_EVENTO_CTRL (RETORNO)
        │
        ▼
Volume INDUZIDO / fechado no C5
```

### Otimizações de retorno (V3)

- **GPT-first:** processa candidatos da GPT em vez de varrer todos os enviados
- **6 workers** com hash de etiqueta (sem duplicidade entre workers)
- **Cache** em `DD_PKG_FECHA_CACHE` para dados de carga/produto repetidos

---

## Procedures legadas (referência)

| Procedure | Uso |
|-----------|-----|
| `DD_PRC_BATCH_RETORNO` | V1 original |
| `DD_PRC_BATCH_RETORNO_V2` | Workers + performance intermediária |
| `DD_PRC_BATCH_RETORNO_V3` | **Produção** — GPT-first + 6 workers |
| `DD_PRC_BATCH_HML` | Ciclo único HML (captura+reconcilia+envio+fecho) — job desabilitado em prod |
| `DD_PRC_BATCH_ENVIO_SHARD` | Shard por carga específica — legado |

---

## Tabelas de controle CD2

| Tabela | Função |
|--------|--------|
| `DD_SORTER_EVENTO_CTRL` | Log de eventos por etiqueta (fonte de verdade envio/retorno) |
| `DD_SORTER_BATCH_CARGA_CTRL` | Fila de cargas para workers de envio |
| `DD_SORTER_VINCULO_RETORNO_ETQ` | Vínculo etiqueta ↔ retorno Invent |
| `DD_SORTER_GPT_RETORNO_FILA` | GTT staging GPT retorno (V3) |
