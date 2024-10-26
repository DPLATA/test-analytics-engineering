-- models/staging/staging_bank_marketing.sql
WITH source AS (
    SELECT *
    FROM {{ source('raw', 'raw_bank_marketing') }}
),

cleaned_data AS (
    SELECT
        -- Clean and normalize demographic data
        CAST(age AS INT64) as customer_age,
        CASE
            WHEN job = 'unknown' THEN NULL
            ELSE TRIM(LOWER(job))
        END as occupation,
        CASE
            WHEN marital = 'unknown' THEN NULL
            ELSE TRIM(LOWER(marital))
        END as marital_status,
        CASE
            WHEN education = 'unknown' THEN NULL
            ELSE TRIM(LOWER(education))
        END as education_level,

        -- Clean and normalize loan information
        CASE
            WHEN `default` = 'unknown' THEN NULL  -- Use backticks for reserved keyword
            WHEN `default` = 'yes' THEN TRUE
            WHEN `default` = 'no' THEN FALSE
        END as has_credit_default,
        CASE
            WHEN housing = 'unknown' THEN NULL
            WHEN housing = 'yes' THEN TRUE
            WHEN housing = 'no' THEN FALSE
        END as has_housing_loan,
        CASE
            WHEN loan = 'unknown' THEN NULL
            WHEN loan = 'yes' THEN TRUE
            WHEN loan = 'no' THEN FALSE
        END as has_personal_loan,

        -- Clean campaign contact details
        TRIM(LOWER(contact)) as contact_type,
        CAST(duration AS INT64) as call_duration_seconds,
        TRIM(LOWER(month)) as contact_month,
        CAST(campaign AS INT64) as campaign_contacts,

        -- Clean previous campaign information
        CASE
            WHEN CAST(pdays AS INT64) = 999 THEN NULL
            ELSE CAST(pdays AS INT64)
        END as days_since_previous_contact,
        CAST(previous AS INT64) as previous_campaign_contacts,
        CASE
            WHEN poutcome = 'nonexistent' THEN NULL
            ELSE TRIM(LOWER(poutcome))
        END as previous_outcome,

        -- Clean economic indicators
        CAST(emp_var_rate AS FLOAT64) as employment_variation_rate,
        CAST(cons_price_idx AS FLOAT64) as consumer_price_index,
        CAST(cons_conf_idx AS FLOAT64) as consumer_confidence_index,
        CAST(euribor3m AS FLOAT64) as euribor_3m_rate,
        CAST(nr_employed AS FLOAT64) as number_employed,

        -- Clean target variable
        CASE
            WHEN y = 'yes' THEN TRUE
            WHEN y = 'no' THEN FALSE
        END as is_subscribed
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
        END as age_segment,

        CASE
            WHEN call_duration_seconds < 60 THEN 'Very Short'
            WHEN call_duration_seconds < 180 THEN 'Short'
            WHEN call_duration_seconds < 300 THEN 'Medium'
            ELSE 'Long'
        END as call_duration_category,

        -- Add campaign contact intensity
        CASE
            WHEN campaign_contacts = 1 THEN 'Single Contact'
            WHEN campaign_contacts <= 3 THEN 'Few Contacts'
            WHEN campaign_contacts <= 5 THEN 'Multiple Contacts'
            ELSE 'Intensive Follow-up'
        END as contact_intensity
    FROM cleaned_data
)

-- Filter out irrelevant records
SELECT *
FROM enhanced_data
WHERE call_duration_seconds > 0  -- Remove failed calls
  AND contact_type IS NOT NULL   -- Remove records with missing contact type
