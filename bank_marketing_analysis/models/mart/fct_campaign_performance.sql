-- models/mart/kpi_bank_marketing.sql
WITH campaign_metrics AS (
    SELECT
        -- Overall conversion metrics
        COUNT(*) as total_contacts,
        COUNTIF(is_subscribed) as successful_conversions,
        ROUND(SAFE_DIVIDE(COUNTIF(is_subscribed) * 100.0, NULLIF(COUNT(*), 0)), 2) as conversion_rate,


        -- Conversion by contact type
        ROUND(SAFE_DIVIDE(COUNTIF(is_subscribed AND contact_type = 'cellular') * 100.0,
            NULLIF(COUNTIF(contact_type = 'cellular'), 0)), 2) as cellular_conversion_rate,
        ROUND(SAFE_DIVIDE(COUNTIF(is_subscribed AND contact_type = 'telephone') * 100.0,
            NULLIF(COUNTIF(contact_type = 'telephone'), 0)), 2) as telephone_conversion_rate,


        -- Average call duration metrics
        ROUND(AVG(call_duration_seconds), 2) as avg_call_duration,
        ROUND(AVG(CASE WHEN is_subscribed THEN call_duration_seconds END), 2) as avg_successful_call_duration
    FROM {{ ref('staging_bank_marketing') }}
),

customer_segments AS (
    SELECT
        -- Age segment analysis
        age_segment,
        COUNT(*) as segment_size,
        COUNTIF(is_subscribed) as segment_conversions,
        ROUND(SAFE_DIVIDE(COUNTIF(is_subscribed) * 100.0, NULLIF(COUNT(*), 0)), 2) as segment_conversion_rate
    FROM {{ ref('staging_bank_marketing') }}
    GROUP BY age_segment
),

occupation_performance AS (
    SELECT
        occupation,
        COUNT(*) as total_contacts,
        COUNTIF(is_subscribed) as successful_conversions,
        ROUND(SAFE_DIVIDE(COUNTIF(is_subscribed) * 100.0, NULLIF(COUNT(*), 0)), 2) as occupation_conversion_rate,
        ROUND(AVG(call_duration_seconds), 2) as avg_call_duration
    FROM {{ ref('staging_bank_marketing') }}
    WHERE occupation IS NOT NULL
    GROUP BY occupation
    HAVING COUNT(*) >= 100  -- Filter for significant occupation groups
),

contact_efficiency AS (
    SELECT
        contact_intensity,
        COUNT(*) as total_contacts,
        COUNTIF(is_subscribed) as successful_conversions,
        ROUND(SAFE_DIVIDE(COUNTIF(is_subscribed) * 100.0, NULLIF(COUNT(*), 0)), 2) as intensity_conversion_rate,
        ROUND(AVG(call_duration_seconds), 2) as avg_call_duration
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
FROM campaign_metrics cm
CROSS JOIN customer_segments cs
LEFT JOIN occupation_performance op ON 1=1
LEFT JOIN contact_efficiency ce ON 1=1