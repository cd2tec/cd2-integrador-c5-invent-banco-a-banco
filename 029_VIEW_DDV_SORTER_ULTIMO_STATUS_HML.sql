-- =============================================================================
-- VIEW: DDV_SORTER_ULTIMO_STATUS_HML
-- Exportado de CD2@2026-07-06 (fonte: banco remoto)
-- =============================================================================

CREATE OR REPLACE VIEW CD2."DDV_SORTER_ULTIMO_STATUS_HML" AS
SELECT
  t.CODBARRAETQ,
  t.ORIGEM,
  t.STATUS_ORIGEM,
  t.OBS,
  t.DTA_CAPTURA
FROM CD2.DD_SORTER_EVENTO_CTRL t
JOIN (
  SELECT CODBARRAETQ, MAX(ID_EVENTO) AS MAX_ID
  FROM CD2.DD_SORTER_EVENTO_CTRL
  GROUP BY CODBARRAETQ
) x
  ON x.CODBARRAETQ = t.CODBARRAETQ
 AND x.MAX_ID = t.ID_EVENTO
