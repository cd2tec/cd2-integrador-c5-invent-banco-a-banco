# Implantação em novo cliente

## 1. Pré-requisitos

### Schema integrador (ex.: CD2)

```sql
CREATE USER CD2 IDENTIFIED BY <senha>
  DEFAULT TABLESPACE <ts> QUOTA UNLIMITED ON <ts>;
GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE PROCEDURE,
      CREATE SEQUENCE, CREATE JOB TO CD2;
```

### Database link Invent

```sql
-- Como DBA ou CD2 (se tiver privilégio)
CREATE DATABASE LINK INVENT CONNECT TO <user_invent>
  IDENTIFIED BY <senha> USING '<tns_invent>';

-- Teste
SELECT COUNT(*) FROM "GPT_INTEGRA_REMESSA"@INVENT WHERE ROWNUM = 1;
```

Tabelas remotas usadas:
- `GPT_INTEGRA_REMESSA` (envio)
- `GPT_RETORNO_MONTAGEM_PALETES` (+ itens, conforme views)
- `GPT_CANCELAMENTO_REMESSAS` (se aplicável)

### Grants Consinco

Executar **`045_GRANTS_CONSINCO_PARA_CD2.sql`** como owner **CONSINCO** (ou DBA).  
Ajustar `DEFINE GRANTEE` e `DEFINE OWNER` no script.

---

## 2. Ordem de execução dos scripts

Conectar como **CD2** e executar em ordem:

```
@001_SEQUENCE_...
@002_SEQUENCE_...
@003_TABLE_...
...
@043_PROCEDURE_DD_PRC_BATCH_RETORNO_V3.sql
```

Ou via SQL\*Plus:

```bash
for f in $(ls [0-9][0-9][0-9]_*.sql | sort); do echo "@$f" | sqlplus CD2/senha@tns; done
```

**Não** executar `044` e `045` na mesma sessão CD2:
- `045` → sessão CONSINCO
- `044` → sessão CD2 (após compilação OK)

---

## 3. Compilação

```sql
SELECT object_name, object_type, status
  FROM user_objects
 WHERE object_name LIKE 'DD_%'
 ORDER BY object_type, object_name;
-- Esperado: 0 INVALID
```

Se INVALID, recompilar:

```sql
ALTER PROCEDURE DD_PRC_FECHA_C5_ETIQUETA COMPILE;
-- ou
BEGIN DBMS_UTILITY.COMPILE_SCHEMA('CD2'); END;
/
```

---

## 4. Jobs de produção

Executar `044_JOBS_PROD_ENVIO_3W_RETORNO_6W.sql` ou criar manualmente:

- **3 workers envio** — intervalo 5 min, `P_LIMIT => 200`
- **6 workers retorno V3** — intervalo 5 min, `P_LIMIT => 100`

Verificar:

```sql
SELECT job_name, enabled, state, next_run_date
  FROM user_scheduler_jobs
 WHERE job_name LIKE 'DD_JOB_%'
 ORDER BY job_name;
```

---

## 5. Primeira carga de teste

1. Inserir etiqueta teste em `MLO_INTEGRACAOSORTER` (Consinco)
2. Aguardar ciclo envio (5 min) ou:

```sql
BEGIN CD2.DD_PRC_BATCH_CARGA_SYNC; END;
BEGIN CD2.DD_PRC_BATCH_ENVIO_WORKER('W1', 50); END;
```

3. Validar evento:

```sql
SELECT * FROM cd2.dd_sorter_evento_ctrl
 WHERE codbarraetq = '<etq>' AND origem = 'ENVIO'
 ORDER BY dta_captura DESC;
-- Esperado: ENVIADO_INVENT com OBS 'INTEGRACAO TOTAL DESTINO'
```

4. Validar GPT:

```sql
SELECT * FROM "GPT_INTEGRA_REMESSA"@INVENT
 WHERE onda = <nrocarga> AND seqproduto = <prod>;
```

---

## 6. Ajustes por cliente

| Item | Onde ajustar |
|------|----------------|
| Nome do dblink | Views/procedures com `@INVENT` |
| Owner Consinco | Grants `045` |
| Nº workers | `044` — pode reduzir/aumentar |
| `C_LEVA_MAX_VOLUMES` | Body `034_DD_PRC_ENVIA_C5_INVENT` (default 100) |

---

## 7. Re-export do banco

Para sincronizar este pacote com o banco atual:

```bash
cd monitor_app/backend
node export_cd2_integrador.mjs
```

Depois renumerar/revisar grants (`045` deve permanecer curado, não dump bruto de `user_tab_privs`).
