SELECT 
FROM crosstab('
	SELECT customer."CUS_ID" cus_id, 
	product."PRD_LONG_NAME" as product,
	product."PRD_ID" as product_id
	FROM public."F_Measures" measures
	INNER JOIN public."F_Subscriptions" subs ON 
	subs."CUS_ID" = measures."CUS_ID" AND
	subs."CON_ID" = measures."CON_ID" AND
	subs."PM_ID" = measures."PM_ID" AND
	subs."DATE_ID" = measures."DATE_ID" AND
	subs."BM_ID" = measures."BM_ID"
	INNER JOIN public."D_Product" product on product."PRD_ID" = subs."PRD_ID"
	INNER JOIN PUBLIC."D_Customer" customer on customer."CUS_ID" = measures."CUS_ID"')
AS ct (cus_id integer, prod1 integer, prod2 integer, prod3 integer, prod4 integer, prod5 integer, prod6 integer, prod7 integer, prod8 integer, prod9 integer, prod10 integer, prod11 integer);
