WITH INVOICE_BASE AS( 
    SELECT 
        TRIM(REFERENCIA) AS ORDEN_DE_SUMINISTRO
        , TRIM(FACTURA) AS FACTURA
        , TOTAL
        , TRIM(UUID_DESCRIPCION) AS UUID_DESCRIPCION
        , UUID
        , FOLIO
        , FECHA
        , NOMBRE
        , RFC
        , DESCRIPCION
        , CANTIDAD
        , TRY_CAST(REPLACE(IMPORTE, ',', '') AS NUMBER(38, 2)) AS IMPORTE
        , ETL_FILE_NAME
    FROM {{ source('IMSS_BIENESTAR', 'INVOICING') }} 
    WHERE UUID_DESCRIPCION ILIKE '%vigente%'
)

, LATEST_INVOICES AS ( 
    SELECT
        ORDEN_DE_SUMINISTRO
        , FACTURA
        , TOTAL
        , UUID_DESCRIPCION
        , UUID
        , FOLIO
        , FECHA
        , NOMBRE
        , RFC
        , DESCRIPCION
        , CANTIDAD
        , IMPORTE
        ,TO_TIMESTAMP(
            REGEXP_REPLACE(
                REGEXP_SUBSTR(ETL_FILE_NAME, '\\d{2}-\\d{2}-\\d{4}\\s+\\d{2}\\s+\\d{2}'), 
                '(\\d{2}-\\d{2}-\\d{4}\\s+\\d{2})\\s+(\\d{2})', 
                '\\1:\\2'
            ), 
            'DD-MM-YYYY HH24:MI'
        ) AS BATCH_DATE
        ,CURRENT_TIMESTAMP() AS ETL_LOAD_DATE
    FROM INVOICE_BASE
    QUALIFY ROW_NUMBER() OVER(PARTITION BY ORDEN_DE_SUMINISTRO ORDER BY BATCH_DATE DESC) = 1 
)

SELECT 
    ORDEN_DE_SUMINISTRO
    , FACTURA
    , TOTAL
    , UUID_DESCRIPCION
    , UUID
    , FOLIO
    , FECHA
    , NOMBRE
    , RFC
    , DESCRIPCION
    , CANTIDAD
    , IMPORTE
    , BATCH_DATE
    , ETL_LOAD_DATE
FROM LATEST_INVOICES 