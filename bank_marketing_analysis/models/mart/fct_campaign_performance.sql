-- models/mart/kpi_bank_marketing.sql
WITH campaign_metrics AS (
    SELECT
        -- Overall conversion metrics
        COUNT(*) AS total_contacts,
        COUNTIF(is_subscribed) AS successful_conversions,
        ROUND(
            SAFE_DIVIDE(COUNTIF(is_subscribed) * 100.0, NULLIF(COUNT(*), 0)), 2
        ) AS conversion_rate,


        -- Conversion by contact type
        ROUND(SAFE_DIVIDE(
            COUNTIF(is_subscribed AND contact_type = 'cellular') * 100.0,
            NULLIF(COUNTIF(contact_type = 'cellular'), 0)
        ), 2) AS cellular_conversion_rate,
        ROUND(SAFE_DIVIDE(
            COUNTIF(is_subscribed AND contact_type = 'telephone') * 100.0,
            NULLIF(COUNTIF(contact_type = 'telephone'), 0)
        ), 2) AS telephone_conversion_rate,


        -- Average call duration metrics
        ROUND(AVG(call_duration_seconds), 2) AS avg_call_duration,
        ROUND(AVG(CASE WHEN is_subscribed THEN call_duration_seconds END), 2)
            AS avg_successful_call_duration
    FROM {{ ref('staging_bank_marketing') }}
),

customer_segments AS (
    SELECT
        -- Age segment analysis
        age_segment,
        COUNT(*) AS segment_size,
        COUNTIF(is_subscribed) AS segment_conversions,
        ROUND(
            SAFE_DIVIDE(COUNTIF(is_subscribed) * 100.0, NULLIF(COUNT(*), 0)), 2
        ) AS segment_conversion_rate
    FROM {{ ref('staging_bank_marketing') }}
    GROUP BY age_segment
),

occupation_performance AS (
    SELECT
        occupation,
        COUNT(*) AS total_contacts,
        COUNTIF(is_subscribed) AS successful_conversions,
        ROUND(
            SAFE_DIVIDE(COUNTIF(is_subscribed) * 100.0, NULLIF(COUNT(*), 0)), 2
        ) AS occupation_conversion_rate,
        ROUND(AVG(call_duration_seconds), 2) AS avg_call_duration
    FROM {{ ref('staging_bank_marketing') }}
    WHERE occupation IS NOT null
    GROUP BY occupation
    HAVING COUNT(*) >= 100  -- Filter for significant occupation groups
),

contact_efficiency AS (
    SELECT
        contact_intensity,
        COUNT(*) AS total_contacts,
        COUNTIF(is_subscribed) AS successful_conversions,
        ROUND(
            SAFE_DIVIDE(COUNTIF(is_subscribed) * 100.0, NULLIF(COUNT(*), 0)), 2
        ) AS intensity_conversion_rate,
        ROUND(AVG(call_duration_seconds), 2) AS avg_call_duration
    FROM {{ ref('staging_bank_marketing') }}
    GROUP BY contact_intensity
)

-- Combine all KPIs
SELECT
    cm.*,
    cs.age_segment,
    cs.segment_size,
    cs.segment_conversions,
    cs.segment_conversion_rate,
    op.occupation,
    op.occupation_conversion_rate,
    ce.contact_intensity,
    ce.intensity_conversion_rate
FROM campaign_metrics AS cm
CROSS JOIN customer_segments AS cs
LEFT JOIN occupation_performance AS op ON 1 = 1
LEFT JOIN contact_efficiency AS ce ON 1 = 1
