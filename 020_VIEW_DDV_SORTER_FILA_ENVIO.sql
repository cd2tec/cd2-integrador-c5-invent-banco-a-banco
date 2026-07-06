-- =============================================================================
-- VIEW: DDV_SORTER_FILA_ENVIO
-- Exportado de CD2@2026-07-06 (fonte: banco remoto)
-- =============================================================================

CREATE OR REPLACE VIEW CD2."DDV_SORTER_FILA_ENVIO" AS
SELECT
  i.CODBARRAETQ,
  i.NROCARGA,
  i.NROEMPRESA,
  i.TIPOCARGA,
  i.SEQPRODUTO,
  i.INDPROCESSADO,
  i.INDOPERACAO,
  i.DTAHORALTERACAO
FROM CONSINCO.MLO_INTEGRACAOSORTER i
