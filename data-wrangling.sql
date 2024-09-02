# Data Transformation - Add new columns

CREATE OR REPLACE TABLE `marketing-campaign-project.data.marketing_data` AS
SELECT *,
   IFNULL((Clicks / NULLIF(Impressions, 0)) * 100, 0) AS CTR,
   IFNULL((Revenue / NULLIF(Clicks, 0)), 0) AS revenue_per_click,
   IFNULL((Revenue / NULLIF(Impressions, 0)), 0) AS revenue_per_impression,
   IFNULL((Time_on_Site / NULLIF(Page_Views, 0)), 0) AS engagement_rate
FROM `marketing-campaign-project.data.marketing_data`;


