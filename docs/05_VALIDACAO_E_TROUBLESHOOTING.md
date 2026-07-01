# Validação e troubleshooting

## Regra de ouro

**"Marcado como enviado" ≠ "chegou no Invent".**  
Sempre cruzar `DD_SORTER_EVENTO_CTRL` com `GPT_INTEGRA_REMESSA@INVENT`.

---

## Protocolo: envio completo de uma carga

### Check 1 — Elegíveis vs enviados reais

```sql
SELECT e.nrocarga,
  COUNT(DISTINCT c.codbarraetq) elegiveis,
  COUNT(DISTINCT CASE WHEN EXISTS (
    SELECT 1 FROM cd2.dd_sorter_evento_ctrl ev
    WHERE ev.codbarraetq = c.codbarraetq AND ev.origem = 'ENVIO'
      AND ev.status_origem = 'ENVIADO_INVENT'
      AND UPPER(ev.obs) LIKE '%INTEGRACAO TOTAL DESTINO%') THEN c.codbarraetq END) enviados_real,
  COUNT(DISTINCT CASE WHEN NOT EXISTS (
    SELECT 1 FROM cd2.dd_sorter_evento_ctrl ev
    WHERE ev.codbarraetq = c.codbarraetq AND ev.origem = 'ENVIO'
      AND ev.status_origem = 'ENVIADO_INVENT'
      AND UPPER(ev.obs) LIKE '%INTEGRACAO TOTAL DESTINO%') THEN c.codbarraetq END) faltam
FROM cd2.ddv_sorter_correlacao c
JOIN cd2.ddv_sorter_correlacao_enriq e ON e.codbarraetq = c.codbarraetq
JOIN consinco.mlo_integracaosorter i ON i.codbarraetq = c.codbarraetq
WHERE e.nrocarga = :carga
  AND NVL(i.indoperacao,' ') <> 'D'
  AND (UPPER(TRIM(NVL(i.tipocarga,'E'))) = 'R' OR NVL(e.qtd_emb_separada,0) > 0)
GROUP BY e.nrocarga;
```

### Check 2 — GPT Invent

```sql
SELECT SUM(r."QUANTIDADE") qtd, COUNT(*) linhas
  FROM "GPT_INTEGRA_REMESSA"@INVENT r
 WHERE r."ONDA" = :carga;
```

### Check 3 — Critério de OK

- `faltam = 0` no Check 1
- Soma GPT condiz com `enviados_real` (pequenas diferenças por agregação em levas)

---

## Sintomas comuns

| Sintoma | Causa provável | Ação |
|---------|----------------|------|
| Volume não chegou na GPT | Evento falso `JA ENVIADO` (histórico) | Neutralizar OBSOLETO + batch |
| Carga não reprocessa volumes novos | Carga CONCLUIDA sem SYNC | Rodar `DD_PRC_BATCH_CARGA_SYNC` |
| `BLOQUEIO_SEM_CODACESSO` | MAP/DUN sem codacesso | Corrigir cadastro; batch reprocessa |
| Retorno lento | Backlog GPT | Verificar 6 workers retorno ativos |
| `ORA-02014` / dblink em view | Compilar V3 + GTT | Usar `DD_PRC_BATCH_RETORNO_V3` |

---

## Validação retorno

```sql
-- Pendentes GPT sem fechamento C5
SELECT COUNT(*) FROM cd2.ddv_sorter_backlog_atual_hml;

-- Vínculos retorno
SELECT COUNT(*) FROM cd2.dd_sorter_vinculo_retorno_etq
 WHERE dta_vinculo >= TRUNC(SYSDATE);
```

---

## Objetos INVALID

```sql
SELECT object_name, object_type FROM user_objects WHERE status = 'INVALID';
```

Recompilar na ordem: package → procedures dependentes.
