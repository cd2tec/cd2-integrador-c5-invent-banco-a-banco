-- =============================================================================
-- VIEW: DDV_SORTER_RETORNO_C5
-- Exportado de CD2@2026-07-06 (fonte: banco remoto)
-- =============================================================================

CREATE OR REPLACE VIEW CD2."DDV_SORTER_RETORNO_C5" AS
SELECT
  m.CODBARRAETQ,
  m.SEQPALETECARREG,
  m.NROEMPRESA,
  m.CODPRODUTIVO,
  m.INDPROCESSADO,
  m.INDOPERACAO,
  m.DTAHORINIMONT,
  m.DTAHORFINALMONT,
  m.DTAHORALTERACAO
FROM CONSINCO.MLO_MONTAGEMSORTER m
