-- Clean and standardize Open Restaurant Applications data
-- One row per application

WITH source AS (
   SELECT * FROM {{ source('raw', 'source_nyc_open_restaurant_apps') }}
), -- Easier to refer to the dbt reference to a long name table this way

cleaned AS (
    SELECT
        -- Get all columns from source, except ones we're transforming below
        -- To do cleaning on them or explicitly cast them as types just in case
        * EXCEPT (
            objectid,
            approved_for_roadway_seating,
            approved_for_sidewalk_seating,
            borough,
            bulding_number,
            business_address,
            census_tract,
            community_board,
            council_district,
            doing_business_as_dba,
            food_service_establishment,
            globalid,
            healthcompliance_terms,
            landmark_district_or_building,
            landmarkdistrict_terms,
            latitude,
            legal_business_name,
            longitude,
            nta,
            qualify_alcohol,
            restaurant_name,
            roadway_dimensions_area,
            roadway_dimensions_length,
            roadway_dimensions_width,
            seating_interest_sidewalk,
            sidewalk_dimensions_area,
            sidewalk_dimensions_length,
            sidewalk_dimensions_width,
            sla_license_type,
            sla_serial_number,
            street,
            time_of_submission,
            zip
       ),

       -- Identifiers
        CAST(objectid AS STRING) AS application_id,

       -- Approval
        CASE
            WHEN LOWER(TRIM(CAST(approved_for_roadway_seating AS STRING))) IN ('yes') THEN TRUE
            WHEN LOWER(TRIM(CAST(approved_for_roadway_seating AS STRING))) IN ('no') THEN FALSE
            ELSE NULL
        END AS approved_for_roadway_seating,

        CASE
            WHEN LOWER(TRIM(CAST(approved_for_sidewalk_seating AS STRING))) IN ('yes') THEN TRUE
            WHEN LOWER(TRIM(CAST(approved_for_sidewalk_seating AS STRING))) IN ('no') THEN FALSE
            ELSE NULL
        END AS approved_for_sidewalk_seating,

        -- Location / identifiers
    
        
        CASE
            WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('MANHATTAN', 'NEW YORK COUNTY') THEN 'Manhattan'
            WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('BRONX', 'THE BRONX') THEN 'Bronx'
            WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('BROOKLYN', 'KINGS COUNTY') THEN 'Brooklyn'
            WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('QUEENS', 'QUEEN', 'QUEENS COUNTY') THEN 'Queens'
            WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('STATEN ISLAND', 'RICHMOND COUNTY') THEN 'Staten Island'
            ELSE 'UNKNOWN'
        END AS borough,
        CAST(bulding_number AS STRING) AS building_number,
        CAST(business_address AS STRING) AS business_address,
        CAST(census_tract AS STRING) AS census_tract,
        CAST(community_board AS STRING) AS community_board,
        CAST(council_district AS STRING) AS council_district,
        CAST(doing_business_as_dba AS STRING) AS doing_business_as_dba,
        CAST(food_service_establishment AS STRING) AS food_service_establishment,
        CAST(globalid AS STRING) AS globalid,
        CAST(healthcompliance_terms AS STRING) AS healthcompliance_terms,
        CAST(landmark_district_or_building AS STRING) AS landmark_district_or_building,
        CAST(landmarkdistrict_terms AS STRING) AS landmarkdistrict_terms,
        SAFE_CAST(latitude AS NUMERIC) AS latitude,
        CAST(legal_business_name AS STRING) AS legal_business_name,
        SAFE_CAST(longitude AS NUMERIC) AS longitude,
        CAST(nta AS STRING) AS nta,
        CASE
            WHEN LOWER(TRIM(CAST(qualify_alcohol AS STRING))) IN ('yes') THEN TRUE
            WHEN LOWER(TRIM(CAST(qualify_alcohol AS STRING))) IN ('no') THEN FALSE
        ELSE NULL
        END AS qualify_alcohol,
        CAST(restaurant_name AS STRING) AS restaurant_name,
        SAFE_CAST(roadway_dimensions_area AS NUMERIC) AS roadway_dimensions_area,
        SAFE_CAST(roadway_dimensions_length AS NUMERIC) AS roadway_dimensions_length,
        SAFE_CAST(roadway_dimensions_width AS NUMERIC) AS roadway_dimensions_width,
        CAST(seating_interest_sidewalk AS STRING) AS seating_interest_sidewalk,
        SAFE_CAST(sidewalk_dimensions_area AS NUMERIC) AS sidewalk_dimensions_area,
        SAFE_CAST(sidewalk_dimensions_length AS NUMERIC) AS sidewalk_dimensions_length,
        SAFE_CAST(sidewalk_dimensions_width AS NUMERIC) AS sidewalk_dimensions_width,
        CAST(sla_license_type AS STRING) AS sla_license_type,
        CAST(sla_serial_number AS STRING) AS sla_serial_number,
        CAST(street AS STRING) AS street,
        CAST(time_of_submission AS TIMESTAMP) AS time_of_submission,


    -- clean zip code, handling several common zip code data problems
        CASE
            WHEN UPPER(TRIM(CAST(zip AS STRING))) IN ('N/A', 'NA') THEN NULL
            WHEN UPPER(TRIM(CAST(zip AS STRING))) = 'ANONYMOUS' THEN 'Anonymous'
            WHEN LENGTH(CAST(zip AS STRING)) = 5 THEN CAST(zip AS STRING)
            WHEN LENGTH(CAST(zip AS STRING)) = 9 THEN CAST(zip AS STRING)
            WHEN LENGTH(CAST(zip AS STRING)) = 10
                AND REGEXP_CONTAINS(CAST(zip AS STRING), r'^\d{5}-\d{4}')
            THEN CAST(zip AS STRING)
            ELSE NULL
        END AS zip,

       -- Metadata
        CURRENT_TIMESTAMP() AS _stg_loaded_at

    FROM source

    -- Filters
    WHERE objectid IS NOT NULL
    AND borough IS NOT NULL

    -- Deduplicate
    QUALIFY ROW_NUMBER() OVER (
    PARTITION BY objectid
    ORDER BY time_of_submission DESC
    ) = 1
)

SELECT * FROM cleaned
-- All should be part of this table: stg_nyc_311_dot
