-- =============================================================================
-- GRANTS Consinco (C5) -> utilizador tecnico do integrador Sorter (CD2)
-- =============================================================================
-- Origem: referencias CONSINCO.* no export HML cd2_full_export_from_hml_2026-05-13
--         (views 009-010, 014-015, procedures 019-022) + scripts operacionais 17/23/33.
--
-- Quem executa: sessao com privilegio para conceder sobre os objetos (normalmente
--             utilizador CONSINCO ou um DBA com GRANT ANY / proxy).
--
-- Ajuste antes de correr:
--   :GRANTEE  -> esquema do integrador (ex.: CD2)
--   :OWNER    -> esquema Consinco (ex.: CONSINCO)
--
-- Notas Oracle:
--   - MERGE exige SELECT + INSERT + UPDATE sobre a tabela alvo (no grantee).
--   - Se algum nome for VIEW ou SYNONYM no vosso ambiente, SELECT pode bastar;
--     mantemos INSERT/UPDATE apenas onde o codigo CD2 faz DML.
--   - Privilegios em tabelas remotas Invent NAO estao aqui (sao via DBLINK).
-- =============================================================================

DEFINE GRANTEE = CD2
DEFINE OWNER   = CONSINCO

-- ---------------------------------------------------------------------------
-- 1) Somente leitura (views CD2 e subqueries nas procedures)
--    MLO_INTEGRACAOSORTER: SELECT em todas as views; UPDATE na procedure fecho.
-- ---------------------------------------------------------------------------
PROMPT === SELECT (e UPDATE onde indicado) ===

GRANT SELECT ON &OWNER..MLO_CARGAEXPED          TO &GRANTEE;
GRANT SELECT ON &OWNER..MAX_EMPRESA             TO &GRANTEE;
GRANT SELECT ON &OWNER..MAP_PRODUTO            TO &GRANTEE;
GRANT SELECT ON &OWNER..MAP_PRODCODIGO         TO &GRANTEE;
GRANT SELECT ON &OWNER..MLO_CARGAEPRODUTO       TO &GRANTEE;
GRANT SELECT ON &OWNER..MAP_FAMEMBALAGEM        TO &GRANTEE;
GRANT SELECT ON &OWNER..MRL_PRODEMPRESAWM      TO &GRANTEE;
GRANT SELECT ON &OWNER..MLO_PRODEMBWM          TO &GRANTEE;
GRANT SELECT ON &OWNER..MLO_LINHASEPARACAO     TO &GRANTEE;
GRANT SELECT ON &OWNER..MLO_TIPESPECIE         TO &GRANTEE;
GRANT SELECT ON &OWNER..MLO_CARGAEPALETE       TO &GRANTEE;
GRANT SELECT ON &OWNER..MLO_PALETE             TO &GRANTEE;
-- MLO_CARGARECEB: SELECT na view enriquecida + MERGE no fecho (privilegios na secao 2)

GRANT SELECT ON &OWNER..MLO_PRODUTIVO          TO &GRANTEE;

-- Integracao: leitura em views + batch; UPDATE no fechamento controlado
GRANT SELECT, UPDATE ON &OWNER..MLO_INTEGRACAOSORTER TO &GRANTEE;

-- Montagem: leitura + INSERT/UPDATE no fechamento (cria/atualiza retorno)
GRANT SELECT, INSERT, UPDATE ON &OWNER..MLO_MONTAGEMSORTER TO &GRANTEE;

-- ---------------------------------------------------------------------------
-- 2) MERGE / UPDATE (fechamento DD_PRC_FECHA_C5_ETIQUETA)
-- ---------------------------------------------------------------------------
PROMPT === MERGE e UPDATE (fechamento) ===

GRANT SELECT, INSERT, UPDATE ON &OWNER..MLO_CARREGAMENTOPORPALETE   TO &GRANTEE;
GRANT SELECT ON &OWNER..S_MLO_CARREGAMENTOPORPALETE                 TO &GRANTEE;
GRANT SELECT, INSERT, UPDATE ON &OWNER..MLO_PALETECARREG          TO &GRANTEE;
GRANT SELECT, INSERT, UPDATE ON &OWNER..MLO_PALCARREGRF           TO &GRANTEE;
GRANT SELECT, INSERT, UPDATE ON &OWNER..MLO_CARREGAMENTOPORPALMASTER TO &GRANTEE;
GRANT SELECT, INSERT, UPDATE ON &OWNER..MLO_CHECAGEMSORTER        TO &GRANTEE;
GRANT SELECT, INSERT, UPDATE ON &OWNER..MLO_PRODUTIVOSORTER        TO &GRANTEE;
GRANT SELECT, INSERT, UPDATE ON &OWNER..MLO_TIPESPECIESORTER        TO &GRANTEE;
GRANT SELECT, INSERT, UPDATE ON &OWNER..MLO_PRODUTOSORTER         TO &GRANTEE;
GRANT SELECT, INSERT, UPDATE ON &OWNER..MLO_CARGARECEB            TO &GRANTEE;

-- Apenas UPDATE no corpo atual (mas SELECT necessario para WHERE)
GRANT SELECT, UPDATE ON &OWNER..MLO_PALETEQTDE TO &GRANTEE;

-- ---------------------------------------------------------------------------
-- 3) Fim
-- ---------------------------------------------------------------------------
PROMPT === Grants Consinco para integrador concluidos (rever erros ORA-01917 se objeto inexistente no vosso release C5) ===

-- ---------------------------------------------------------------------------
-- Apendice A — Inventario de objetos CONSINCO cobertos (verificar apos alterar DDL CD2)
-- ---------------------------------------------------------------------------
--  MLO_CARGAEXPED, MAX_EMPRESA, MAP_PRODUTO, MAP_PRODCODIGO, MLO_CARGAEPRODUTO,
--  MAP_FAMEMBALAGEM, MRL_PRODEMPRESAWM, MLO_PRODEMBWM, MLO_LINHASEPARACAO,
--  MLO_TIPESPECIE, MLO_CARGAEPALETE, MLO_PALETE, MLO_PRODUTIVO  -> SELECT
--  MLO_INTEGRACAOSORTER -> SELECT, UPDATE
--  MLO_MONTAGEMSORTER   -> SELECT, INSERT, UPDATE
--  S_MLO_CARREGAMENTOPORPALETE -> SELECT (NEXTVAL no fechamento 022)
--  MLO_CARREGAMENTOPORPALETE, MLO_PALETECARREG, MLO_PALCARREGRF,
--  MLO_CARREGAMENTOPORPALMASTER, MLO_CHECAGEMSORTER, MLO_PRODUTIVOSORTER,
--  MLO_TIPESPECIESORTER, MLO_PRODUTOSORTER, MLO_CARGARECEB -> SELECT, INSERT, UPDATE (MERGE)
--  MLO_PALETEQTDE -> SELECT, UPDATE
--
-- Apendice B — OPCIONAL (só se o user CD2 executar scripts de teste/limpeza em CONSINCO)
-- ---------------------------------------------------------------------------
-- GRANT DELETE ON &OWNER..MLO_MONTAGEMSORTER     TO &GRANTEE;   -- ex.: 23_sql_limpeza_massas_hml.sql
-- GRANT DELETE ON &OWNER..MLO_INTEGRACAOSORTER TO &GRANTEE;
-- GRANT INSERT ON &OWNER..MLO_INTEGRACAOSORTER TO &GRANTEE;   -- ex.: 17_sql_soak_test_hml.sql
-- GRANT INSERT ON &OWNER..MLO_MONTAGEMSORTER    TO &GRANTEE;

UNDEFINE GRANTEE
UNDEFINE OWNER
