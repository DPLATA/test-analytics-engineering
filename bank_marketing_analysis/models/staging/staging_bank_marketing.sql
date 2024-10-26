-- models/staging/staging_bank_marketing.sql
WITH source AS (
    SELECT *
    FROM {{ source('raw', 'raw_bank_marketing') }}
),

cleaned_data AS (
    SELECT
        -- Clean and normalize demographic data
        CAST(age AS INT64) AS customer_age,
        CASE
            WHEN job = 'unknown' THEN null
            ELSE TRIM(LOWER(job))
        END AS occupation,
        CASE
            WHEN marital = 'unknown' THEN null
            ELSE TRIM(LOWER(marital))
        END AS marital_status,
        CASE
            WHEN education = 'unknown' THEN null
            ELSE TRIM(LOWER(education))
        END AS education_level,

        -- Clean and normalize loan information
        CASE
            -- Use backticks for reserved keyword
            WHEN `default` = 'unknown' THEN null
            WHEN `default` = 'yes' THEN true
            WHEN `default` = 'no' THEN false
        END AS has_credit_default,
        CASE
            WHEN housing = 'unknown' THEN null
            WHEN housing = 'yes' THEN true
            WHEN housing = 'no' THEN false
        END AS has_housing_loan,
        CASE
            WHEN loan = 'unknown' THEN null
            WHEN loan = 'yes' THEN true
            WHEN loan = 'no' THEN false
        END AS has_personal_loan,

        -- Clean campaign contact details
        TRIM(LOWER(contact)) AS contact_type,
        CAST(duration AS INT64) AS call_duration_seconds,
        TRIM(LOWER(month)) AS contact_month,
        CAST(campaign AS INT64) AS campaign_contacts,

        -- Clean previous campaign information
        CASE
            WHEN CAST(pdays AS INT64) = 999 THEN null
            ELSE CAST(pdays AS INT64)
        END AS days_since_previous_contact,
        CAST(previous AS INT64) AS previous_campaign_contacts,
        CASE
            WHEN poutcome = 'nonexistent' THEN null
            ELSE TRIM(LOWER(poutcome))
        END AS previous_outcome,

        -- Clean economic indicators
        CAST(emp_var_rate AS FLOAT64) AS employment_variation_rate,
        CAST(cons_price_idx AS FLOAT64) AS consumer_price_index,
        CAST(cons_conf_idx AS FLOAT64) AS consumer_confidence_index,
        CAST(euribor3m AS FLOAT64) AS euribor_3m_rate,
        CAST(nr_employed AS FLOAT64) AS number_employed,

        -- Clean target variable
        CASE
            WHEN y = 'yes' THEN true
            WHEN y = 'no' THEN false
        END AS is_subscribed
    FROM source
),

enhanced_data AS (
    SELECT
        *,
        -- Create new columns for analysis
        CASE
            WHEN customer_age < 25 THEN 'Young Adult'
            WHEN customer_age < 35 THEN 'Adult'
            WHEN customer_age < 50 THEN 'Middle Aged'
            ELSE 'Senior'
        END AS age_segment,

        CASE
            WHEN call_duration_seconds < 60 THEN 'Very Short'
            WHEN call_duration_seconds < 180 THEN 'Short'
            WHEN call_duration_seconds < 300 THEN 'Medium'
            ELSE 'Long'
        END AS call_duration_category,

        -- Add campaign contact intensity
        CASE
            WHEN campaign_contacts = 1 THEN 'Single Contact'
            WHEN campaign_contacts <= 3 THEN 'Few Contacts'
            WHEN campaign_contacts <= 5 THEN 'Multiple Contacts'
            ELSE 'Intensive Follow-up'
        END AS contact_intensity
    FROM cleaned_data
)

-- Filter out irrelevant records
SELECT *
FROM enhanced_data
WHERE
    call_duration_seconds > 0  -- Remove failed calls
    AND contact_type IS NOT null   -- Remove records with missing contact type
