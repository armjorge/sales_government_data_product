WITH BASE_SAGI AS ( 
    SELECT 
        *
        , COALESCE(
            -- Matches: 2026-10-05 22h 59
            TRY_TO_TIMESTAMP(
                REGEXP_SUBSTR(ETL_FILE_NAME, '\\d{4}-\\d{2}-\\d{2}\\s+\\d{2}h\\s+\\d{2}'), 
                'YYYY-MM-DD HH24"h" MI'
            ),
            -- Matches: 2026-10-05 22h
            TRY_TO_TIMESTAMP(
                REGEXP_SUBSTR(ETL_FILE_NAME, '\\d{4}-\\d{2}-\\d{2}\\s+\\d{2}h'), 
                'YYYY-MM-DD HH24"h"'
            ),
            -- Matches: 2026 10 02 16h
            TRY_TO_TIMESTAMP(
                REGEXP_SUBSTR(ETL_FILE_NAME, '\\d{4}\\s+\\d{2}\\s+\\d{2}\\s+\\d{2}h'), 
                'YYYY MM DD HH24"h"'
            ),
            -- Matches: 02-10-2026 16 31
            TRY_TO_TIMESTAMP(
                REGEXP_SUBSTR(ETL_FILE_NAME, '\\d{2}-\\d{2}-\\d{4}\\s+\\d{2}\\s+\\d{2}'), 
                'DD-MM-YYYY HH24 MI'
            ),
            -- Matches: 02-10-2026 16
            TRY_TO_TIMESTAMP(
                REGEXP_SUBSTR(ETL_FILE_NAME, '\\d{2}-\\d{2}-\\d{4}\\s+\\d{2}'), 
                'DD-MM-YYYY HH24'
            )
        ) AS BATCH_DATE
    FROM {{ source('IMSS_BIENESTAR', 'SAGI') }} 
    WHERE ESTADO_DE_LA_FACTURA NOT ILIKE 'Cancelado'
) 

, LATEST_ORDERS AS ( 
    SELECT 
        PROVEEDOR
        , RFC
        , TRIM(NUMERO_DE_CONTRATO) AS NUMERO_DE_CONTRATO
        , TRIM(ORDEN_DE_SUMINISTRO) AS ORDEN_DE_SUMINISTRO
        , NUMERO_DE_FACTURA
        , FOLIO_FISCAL
        , TOTAL
        , CLUES
        , ESTADO_DE_LA_FACTURA
        , OPCIONES
        , BATCH_DATE
    FROM BASE_SAGI 
    WHERE ORDEN_DE_SUMINISTRO IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY ORDEN_DE_SUMINISTRO 
        ORDER BY BATCH_DATE DESC NULLS LAST
    ) = 1 
) 

SELECT 
    PROVEEDOR
    , RFC
    , NUMERO_DE_CONTRATO
    , ORDEN_DE_SUMINISTRO
    , NUMERO_DE_FACTURA
    , FOLIO_FISCAL
    , TOTAL
    , CLUES
    , ESTADO_DE_LA_FACTURA
    , OPCIONES
    , BATCH_DATE
    , CURRENT_TIMESTAMP() AS ETL_LOAD_DATE
FROM LATEST_ORDERS
