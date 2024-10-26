-- models/intermediate/int_campaign_metrics.sql
WITH campaign_data AS (
    SELECT
        occupation,
        contact_type,
        contact_month,
        is_subscribed,
        call_duration_seconds,
        campaign_contacts
    FROM {{ ref('staging_bank_marketing') }}
)

SELECT
    occupation,
    contact_type,
    contact_month,
    COUNT(*) AS total_contacts,
    -- Changed from COUNT(CASE WHEN...)
    COUNTIF(is_subscribed) AS successful_conversions,
    AVG(call_duration_seconds) AS avg_call_duration,
    MAX(campaign_contacts) AS max_campaign_contacts,
    ROUND(SAFE_DIVIDE(COUNTIF(is_subscribed) * 100.0, NULLIF(COUNT(*), 0)), 2)
        AS conversion_rate
FROM campaign_data
GROUP BY 1, 2, 3
