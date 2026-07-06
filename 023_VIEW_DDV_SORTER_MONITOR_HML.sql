-- =============================================================================
-- VIEW: DDV_SORTER_MONITOR_HML
-- Exportado de CD2@2026-07-06 (fonte: banco remoto)
-- =============================================================================

CREATE OR REPLACE VIEW CD2."DDV_SORTER_MONITOR_HML" AS
SELECT
  TRUNC(DTA_CAPTURA) AS DIA,
  ORIGEM,
  STATUS_ORIGEM,
  COUNT(*) AS QTD
FROM CD2.DD_SORTER_EVENTO_CTRL
GROUP BY TRUNC(DTA_CAPTURA), ORIGEM, STATUS_ORIGEM
