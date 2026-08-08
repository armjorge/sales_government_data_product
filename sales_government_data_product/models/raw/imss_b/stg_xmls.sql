WITH BASE_XMLS AS ( 
    SELECT
        TRIM(UPPER(UUID)) AS UUID 
        ,TRIM(FOLIO) AS FOLIO
        ,FECHA
        ,NOMBRE
        ,RFC
        ,DESCRIPCION
        ,CANTIDAD
        ,REPLACE(IMPORTE, '.0', '')::NUMBER AS IMPORTE
        ,ARCHIVO
        ,ETL_FILE_NAME
        ,TO_TIMESTAMP(
            REGEXP_REPLACE(
                REGEXP_SUBSTR(ETL_FILE_NAME, '\\d{2}-\\d{2}-\\d{4}\\s+\\d{2}\\s+\\d{2}'), 
                '(\\d{2}-\\d{2}-\\d{4}\\s+\\d{2})\\s+(\\d{2})', 
                '\\1:\\2'
            ), 
            'DD-MM-YYYY HH24:MI'
        ) AS BATCH_DATE
    FROM {{ source('IMSS_BIENESTAR', 'INVOICESXMLS') }} 

)

, LATEST_XMLS AS ( 
    SELECT 
    UUID 
    ,FOLIO
    ,FECHA
    ,NOMBRE
    ,RFC
    ,DESCRIPCION
    ,CANTIDAD
    ,IMPORTE
    ,ARCHIVO
    ,ETL_FILE_NAME
    ,BATCH_DATE
    ,CURRENT_TIMESTAMP() AS ETL_LOAD_DATE
FROM BASE_XMLS
QUALIFY 
ROW_NUMBER() OVER(PARTITION BY UUID ORDER BY BATCH_DATE DESC) = 1
)

SELECT
    UUID
    ,FOLIO
    ,FECHA
    ,NOMBRE
    ,RFC
    ,DESCRIPCION
    ,CANTIDAD
    ,IMPORTE
    ,ARCHIVO
    ,ETL_FILE_NAME
    ,BATCH_DATE
    ,ETL_LOAD_DATE
FROM LATEST_XMLS