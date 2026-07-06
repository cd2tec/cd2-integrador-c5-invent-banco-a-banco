-- =============================================================================
-- VIEW: DDV_SORTER_CORRELACAO
-- Exportado de CD2@2026-07-06 (fonte: banco remoto)
-- =============================================================================

CREATE OR REPLACE VIEW CD2."DDV_SORTER_CORRELACAO" AS
SELECT
  c.CODBARRAETQ,
  c.NROCARGA,
  c.NROEMPRESA,
  c.TIPOCARGA,
  c.INDPROCESSADO AS C5_PROC,
  i.FKMISSAO,
  i.FKVOLUME,
  i.STATUS_VOLUME,
  i.STATUS_SORTER,
  i.REJEITADO,
  i.DESVIADO,
  i.TIMELEITURA,
  i.TIMEACKN
FROM CD2.DDV_SORTER_FILA_ENVIO c
LEFT JOIN CD2.DDV_SORTER_STATUS_INVENT i
  ON i.CODBARRAETQ = c.CODBARRAETQ
