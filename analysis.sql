# 1. Campaign performance by geography


CREATE OR REPLACE VIEW `marketing-campaign-project.data.geography_campaign_performance` AS
SELECT Geography, State, SUM(SAFE_DIVIDE(Conversions, Clicks)) AS conversion_rate, AVG(engagement_rate) AS avg_engagement_rate
FROM `marketing-campaign-project.data.marketing_data`
GROUP BY Geography, State
ORDER BY conversion_rate DESC, avg_engagement_rate DESC;


# 2. Channel Effectiveness


CREATE OR REPLACE VIEW `marketing-campaign-project.data.channel_effectiveness` AS
SELECT Campaign_Type, Channel_Used, ROUND(AVG(SAFE_DIVIDE(Conversions, Clicks)), 2) AS avg_conversion_rate, ROUND(SUM(Revenue), 2) AS total_revenue
FROM `marketing-campaign-project.data.marketing_data`
GROUP BY Campaign_Type, Channel_Used
ORDER BY total_revenue DESC, avg_conversion_rate DESC;


# 3. Revenue Distribution by Age Group


CREATE OR REPLACE VIEW `marketing-campaign-project.data.revenue_distribution_age` AS
SELECT Age_Group, ROUND(SUM(Revenue), 2) AS total_Revenue, ROUND(SUM(revenue_per_click), 2) AS total_rpc, ROUND(SUM(revenue_per_impression), 2) AS total_rpi
FROM `marketing-campaign-project.data.marketing_data`
GROUP BY Age_Group
ORDER BY total_revenue DESC;


# 4. Campaign performance by geography comparison


CREATE OR REPLACE VIEW `marketing-campaign-project.data.state_country_comparison` AS
WITH geography_avg_cr AS(
  SELECT Geography, Campaign_Type, ROUND(AVG(SAFE_DIVIDE(Conversions, Clicks)), 2) AS country_avg_conversion_rate
  FROM `marketing-campaign-project.data.marketing_data`
  GROUP BY Geography, Campaign_Type
),
state_avg_cr AS(
  SELECT Geography, State, Campaign_Type, ROUND(AVG(SAFE_DIVIDE(Conversions, Clicks)), 2) AS state_avg_conversion_rate
  FROM `marketing-campaign-project.data.marketing_data`
  GROUP BY Geography, State, Campaign_Type
)


SELECT scr.Geography, scr.State, scr.Campaign_Type, scr.state_avg_conversion_rate, gcr.country_avg_conversion_rate, ROUND(ABS(scr.state_avg_conversion_rate - gcr.country_avg_conversion_rate), 2) AS difference_avg_conversion_rate
FROM geography_avg_cr gcr
JOIN state_avg_cr scr
ON gcr.Geography = scr.Geography AND
gcr.Campaign_Type = scr.Campaign_Type
ORDER BY scr.Geography, scr.State, difference_avg_conversion_rate DESC;


# 5. Top 10 performing campaigns yearly based on ROI


CREATE OR REPLACE VIEW `marketing-campaign-project.data.top_5_campaigns` AS
WITH metrics AS(
  SELECT
    EXTRACT(YEAR FROM Date) AS Year,
    Campaign_Type,
    Channel_Used,
    ROUND(SUM(Clicks), 2) AS total_clicks,
    ROUND(SUM(Impressions), 2) AS total_impressions,
    ROUND(SUM(Revenue), 2) AS total_revenue,
    ROUND(SUM(Acquisition_Cost), 2) AS total_cost,
    ROUND(SUM(ROI), 2) AS total_ROI
  FROM
    `marketing-campaign-project.data.marketing_data`
  GROUP BY
    Year,
    Campaign_Type,
    Channel_Used
),
top_campaigns AS(
  SELECT *,
  RANK() OVER(PARTITION BY Year ORDER BY total_ROI DESC) AS rank_roi
  FROM metrics
)
SELECT *
FROM top_campaigns
WHERE rank_roi <= 5
ORDER BY top_campaigns.YEAR, rank_roi DESC;


# 6. Channel performance in terms of monthly revenue over the years


CREATE OR REPLACE VIEW `marketing-campaign-project.data.channel_monthly_revenue` AS
WITH revenue_table AS(
  SELECT
    Channel_Used,
    EXTRACT(YEAR FROM Date) AS year,
    EXTRACT(MONTH FROM Date) AS month,
    ROUND(SUM(Revenue), 2) AS monthly_revenue
  FROM `marketing-campaign-project.data.marketing_data`
  GROUP BY Channel_Used, year, month
)
SELECT
  *,
  SUM(monthly_revenue) OVER(PARTITION BY Channel_Used ORDER BY year, month) AS cumulative_revenue,
  monthly_revenue - LAG(monthly_revenue) OVER(PARTITION BY Channel_Used, month ORDER BY year) AS yoy_monthly_revenue_diff
FROM revenue_table
ORDER BY Channel_Used, year, month;
