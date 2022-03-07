-- Use for relation between contract type and churn
drop view v_churn;
create or replace view v_churn as 
SELECT 
CASE "MS_Churn" WHEN '1' THEN 'Yes' ELSE 'No' END as churned,
"MS_Tenure" as tenure,
contract."CON_NAME" as contract,
"MS_Charge_Month" as monthly_charge,
"MS_Charge_Total" as total_charge
FROM public."F_Measures" measures
inner join public."D_Contract"  contract on contract."CON_ID" = measures."CON_ID";

--Use for correlation matrix
DROP VIEW v_correlation;
CREATE OR REPLACE VIEW v_correlation as 
SELECT 
"MS_Churn" AS churned,
"MS_Tenure"/12 AS tenure_years,
"CON_ID" AS contract_type,
CASE WHEN "CUS_Gender" = 'Male' THEN 1 ELSE 0 END as gender
FROM public."F_Measures" measures
INNER JOIN public."D_Customer" cus ON cus."CUS_ID" = measures."CUS_ID";

-- single products
DROP VIEW v_products;
CREATE OR REPLACE VIEW v_products as 
SELECT product."PRD_LINE" as product_line,
product."PRD_NAME" as product, 
"SUB" sub_count
FROM public."F_Subscriptions" subs
INNER JOIN public."D_Product" product on product."PRD_ID" = subs."PRD_ID";

-- product churn
DROP VIEW v_product_churn;
CREATE OR REPLACE VIEW v_product_churn as 
SELECT customer."CUS_BKey" customer,
product."PRD_LONG_NAME" as product,
case measures."MS_Churn" when 0 then 'No' ELSE 'Yes' END as churned
FROM public."F_Measures" measures
INNER JOIN public."F_Subscriptions" subs ON 
subs."CUS_ID" = measures."CUS_ID" AND
subs."CON_ID" = measures."CON_ID" AND
subs."PM_ID" = measures."PM_ID" AND
subs."DATE_ID" = measures."DATE_ID" AND
subs."BM_ID" = measures."BM_ID"
INNER JOIN public."D_Product" product on product."PRD_ID" = subs."PRD_ID"
INNER JOIN PUBLIC."D_Customer" customer on customer."CUS_ID" = measures."CUS_ID";

DROP VIEW v_single_sub;
CREATE OR REPLACE VIEW v_single_sub AS
SELECT "PRD_LONG_NAME" as product,  count(*) as product_count
FROM public."F_Subscriptions" sub
INNER JOIN public."D_Product" prod on prod."PRD_ID" = sub."PRD_ID"
group by "PRD_LONG_NAME"
order by 2 desc;

--- product combinations
drop view v_double_sub;
CREATE OR replace VIEW v_double_sub AS
SELECT 
prod_1 || ' - ' || prod_2 as product_bundle,
prod_1_bkey || ' - ' || prod_2_bkey as product_code_bundle,
counter as product_count
FROM 
(
SELECT bundles.*, row_number() over (order by counter desc) as row
FROM (
	SELECT prod1."PRD_LONG_NAME" prod_1 , 
	prod2."PRD_LONG_NAME" prod_2, 
	prod1."PRD_BKEY" prod_1_bkey,
	prod2."PRD_BKEY" prod_2_bkey,
	count(*) counter
FROM public."F_Subscriptions" sub1
INNER JOIN public."F_Subscriptions" sub2 ON sub1."CUS_ID" = sub2."CUS_ID" 
INNER JOIN public."D_Product" prod1 on prod1."PRD_ID" = sub1."PRD_ID"
INNER JOIN public."D_Product" prod2 on prod2."PRD_ID" = sub2."PRD_ID"
WHERE sub1."PRD_ID" <> sub2."PRD_ID"
GROUP BY prod1."PRD_LONG_NAME" , prod2."PRD_LONG_NAME", prod1."PRD_BKEY", prod2."PRD_BKEY"
ORDER BY 3 DESC
) bundles
) product_pair
WHERE product_pair.row % 2 = 0;