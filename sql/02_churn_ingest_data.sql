
INSERT INTO "D_Customer" (
	"CUS_ID",
	"CUS_BKey",
	"CUS_Gender",
	"CUS_Partner",
	"CUS_Dependents",
	"START_DATE",
	"END_DATE" 
	)
SELECT 
 	ROW_NUMBER() OVER(), 
	"customerID",
	gender, 
	case "SeniorCitizen" 
		when 0 then 'No' else 'Yes' end 
	Partner, 
	"Dependents",
	current_timestamp,
	current_timestamp + interval '100 year'
FROM s_churn;

INSERT INTO "D_Contract" (
	"CON_ID",
	"CON_BKEY",
	"CON_NAME",
	"START_DATE",
	"END_DATE" 
)
SELECT '0', 'UNK', 'Unknown', current_timestamp, current_timestamp + interval '100 year'
UNION
SELECT DISTINCT ROW_NUMBER() OVER(), 
CASE "Contract"
	WHEN 'One year' THEN '1Y'
	WHEN 'Month-to-month' THEN 'M2M'
	WHEN 'Two year' THEN '2Y'
	ELSE
		'Unknown'
	END, 
	"Contract",
	current_timestamp,
	current_timestamp + interval '100 year'
FROM (SELECT DISTINCT "Contract" from public.s_churn)  as Contract;

INSERT INTO "D_Payment_Method" (
	"PM_ID",
	"PM_BKEY",
	"PM_NAME",
	"START_DATE",
	"END_DATE" 
)
SELECT '0', 'UNK', 'Unknown', current_timestamp, current_timestamp + interval '100 year'
UNION
SELECT DISTINCT ROW_NUMBER() OVER(), 
CASE "PaymentMethod"
	WHEN 'Electronic check' THEN 'EC'
	WHEN 'Credit card (automatic)' THEN 'CC'
	WHEN 'Mailed check' THEN 'MC'
	WHEN 'Bank transfer (automatic)' THEN 'BT'
	ELSE
		'UNK'
	END, 
	"PaymentMethod",
	current_timestamp,
	current_timestamp + interval '100 year'
FROM (SELECT DISTINCT "PaymentMethod" from public.s_churn)  as PM;

INSERT INTO "D_Billing_Method" (
	"BM_ID",
	"BM_BKEY",
	"BM_NAME",
	"START_DATE",
	"END_DATE" 
)
SELECT '0', 'UNK', 'Unknown', current_timestamp, current_timestamp + interval '100 year'
UNION
SELECT DISTINCT ROW_NUMBER() OVER(), 
CASE "PaperlessBilling"
	WHEN 'Yes' THEN 'NP'
	WHEN 'No' THEN 'PA'
	ELSE
		'UNK'
	END, 
CASE "PaperlessBilling"
	WHEN 'Yes' THEN 'Paperless'
	WHEN 'No' THEN 'Paper'
	ELSE
		'Unknown'
	END,
	current_timestamp,
	current_timestamp + interval '100 year'	
FROM (SELECT DISTINCT "PaperlessBilling" from public.s_churn)  as PM;

-- Put some Date Values into table
do $$
begin
   for yy in 2010..2030 loop
	raise notice 'year: %', yy;
		for mm in 1..12 loop
			INSERT INTO "D_Date" (
				"DATE_ID",
				"CAL_BKEY",
				"CAL_YEAR",
				"CAL_MONTH",
				"CAL_MONTH_START",
				"CAL_MONTH_END")
			VALUES (yy*100+mm, 
					cast(yy*100+mm as TEXT),
					yy,
					mm,
					to_date(cast(yy*10000+mm*100+1 as TEXT),'yyyymmdd'), 
					(date_trunc('month', cast(yy*10000+mm*100+1 as TEXT)::date) + interval '1 month' - interval '1 day')::date
				   );
			
			raise notice 'month: %', mm;
		end loop;
   end loop;
end; $$

-- Derived Product values
INSERT INTO "D_Product" (
	"PRD_ID",
	"PRD_BKEY",
	"PRD_LINE",
	"PRD_NAME",
	"PRD_LONG_NAME",
	"START_DATE",
	"END_DATE" 
	)
VALUES 
	(0, 'UNK', 'Unknown', 'Unknown', 'Unknown', current_timestamp, current_timestamp + interval '100 year'),
	(1, 'IDSL', 'Internet', 'DSL', 'Internet-DSL', current_timestamp, current_timestamp + interval '100 year'),
	(2, 'IFIB','Internet', 'Fiber',  'Internet-Fiber', current_timestamp, current_timestamp + interval '100 year'),
	(3, 'PHS', 'Phone', 'Single', 'Phone-Single', current_timestamp, current_timestamp + interval '100 year'),
 	(4, 'PHM', 'Phone', 'Multiple', 'Phone-Multi', current_timestamp, current_timestamp + interval '100 year'),
 	(5, 'OLS', 'Online Security', 'Online Security', 'Online Security', current_timestamp, current_timestamp + interval '100 year'),
 	(6, 'TCSU', 'Tech. Support', 'Tech. Support', 'Tech. Support', current_timestamp, current_timestamp + interval '100 year'), 
 	(7, 'STRM', 'Streaming', 'Movies', 'Streaming-Movies', current_timestamp, current_timestamp + interval '100 year'),
 	(8, 'STRTV', 'Streaming', 'TV', 'Streaming-TV', current_timestamp, current_timestamp + interval '100 year'),
 	(9, 'OLBU', 'Online Backup', 'Online Backup', 'Online Backup', current_timestamp, current_timestamp + interval '100 year'),
 	(10, 'DEVP', 'Device Protection', 'Device Protection', 'Device Protection', current_timestamp, current_timestamp + interval '100 year');
	
--Assuming Date is Feb 2022
TRUNCATE TABLE "F_Measures";
INSERT INTO "F_Measures" (
	"CUS_ID",
	"CON_ID",
	"PM_ID",
	"DATE_ID",
	"BM_ID",
	"MS_Charge_Month",
	"MS_Charge_Total",
	"MS_Churn",
	"MS_Tenure"
	)
SELECT "D_Customer"."CUS_ID",
	"D_Contract"."CON_ID",
	"D_Payment_Method"."PM_ID",
	202202 AS "DATE_ID",
	CASE ch."PaperlessBilling" when 'No' THEN 1 ELSE 2 END AS "BM_ID",
 	ch."MonthlyCharges" ,
 	ch."TotalCharges",
	CASE "Churn" WHEN 'No' THEN 0 ELSE 1 END "Churn",
	ch.tenure
FROM s_churn ch
inner join "D_Customer" on "CUS_BKey" = ch."customerID"
inner join "D_Contract" on "CON_NAME" = ch."Contract"
inner join "D_Payment_Method" on "PM_NAME" = ch."PaymentMethod";

-- Do some rudimentary tests
select sum("MS_Charge_Total") FROM "F_Measures";

-- I would never ever ever write code as dodgy as this for a client
DO $$
DECLARE
    product_cur CURSOR FOR
	SELECT "D_Customer"."CUS_ID",
		"D_Contract"."CON_ID",
		"D_Payment_Method"."PM_ID",
		202202 AS "DATE_ID",
		CASE ch."PaperlessBilling" when 'No' THEN 1 ELSE 2 END AS "BM_ID",
		ch."PhoneService",
		ch."MultipleLines",
		ch."InternetService",
		ch."OnlineSecurity",
		ch."OnlineBackup",
		ch."DeviceProtection",
		ch."TechSupport",
		ch."StreamingTV",
		ch."StreamingMovies"
	FROM s_churn ch
	inner join "D_Customer" on "CUS_BKey" = ch."customerID"
	inner join "D_Contract" on "CON_NAME" = ch."Contract"
	inner join "D_Payment_Method" on "PM_NAME" = ch."PaymentMethod";

    product_Skey int; funky_val smallint;
BEGIN
    FOR prod_record IN product_cur LOOP
		-- Phone Service
		IF prod_record."PhoneService" = 'Yes' THEN
			IF prod_record."MultipleLines" = 'Yes' THEN 
				product_Skey:=4; 
			ELSE 
				product_Skey:=3;
			END IF;
			
			funky_val = "CHURN_INS_F_SUB"(
				prod_record."CUS_ID",
				prod_record."CON_ID",
				prod_record."PM_ID",
				prod_record."DATE_ID",
				prod_record."BM_ID",
				product_Skey
				);
		END IF;
		
		IF prod_record."InternetService" IN ('DSL', 'Fiber optic') THEN
			IF prod_record."InternetService" = 'DSL' THEN
				product_Skey:=1; 
			ELSE 
				product_Skey:=2;
			END IF;
			funky_val = "CHURN_INS_F_SUB"(
				prod_record."CUS_ID",
				prod_record."CON_ID",
				prod_record."PM_ID",
				prod_record."DATE_ID",
				prod_record."BM_ID",
				product_Skey
				);
		END IF;

		IF prod_record."OnlineSecurity" = 'Yes' THEN
			product_Skey:=5; 

			funky_val = "CHURN_INS_F_SUB"(
				prod_record."CUS_ID",
				prod_record."CON_ID",
				prod_record."PM_ID",
				prod_record."DATE_ID",
				prod_record."BM_ID",
				product_Skey
				);
		END IF;

		IF prod_record."OnlineBackup" = 'Yes' THEN
			product_Skey:=9; 

			funky_val = "CHURN_INS_F_SUB"(
				prod_record."CUS_ID",
				prod_record."CON_ID",
				prod_record."PM_ID",
				prod_record."DATE_ID",
				prod_record."BM_ID",
				product_Skey
				);
		END IF;


		IF prod_record."DeviceProtection" = 'Yes' THEN
			product_Skey:=10; 

			funky_val = "CHURN_INS_F_SUB"(
				prod_record."CUS_ID",
				prod_record."CON_ID",
				prod_record."PM_ID",
				prod_record."DATE_ID",
				prod_record."BM_ID",
				product_Skey
				);
		END IF;

		IF prod_record."TechSupport" = 'Yes' THEN
			product_Skey:=6; 

			funky_val = "CHURN_INS_F_SUB"(
				prod_record."CUS_ID",
				prod_record."CON_ID",
				prod_record."PM_ID",
				prod_record."DATE_ID",
				prod_record."BM_ID",
				product_Skey
				);
		END IF;
		

		IF prod_record."StreamingTV" = 'Yes' THEN
			product_Skey:=8; 

			funky_val = "CHURN_INS_F_SUB"(
				prod_record."CUS_ID",
				prod_record."CON_ID",
				prod_record."PM_ID",
				prod_record."DATE_ID",
				prod_record."BM_ID",
				product_Skey
				);
		END IF;


		IF prod_record."StreamingMovies" = 'Yes' THEN
			product_Skey:=7; 

			funky_val = "CHURN_INS_F_SUB"(
				prod_record."CUS_ID",
				prod_record."CON_ID",
				prod_record."PM_ID",
				prod_record."DATE_ID",
				prod_record."BM_ID",
				product_Skey
				);
		END IF;
    END LOOP;
END$$;

DO $$
DECLARE
    product_cur CURSOR FOR
	SELECT "D_Customer"."CUS_ID",
		"D_Contract"."CON_ID",
		"D_Payment_Method"."PM_ID",
		case when ch."PaperlessBilling" = 'Yes' THEN 2 ELSE 1 END as "BM_ID",
		CASE WHEN ch.tenure=0 THEN 1 ELSE ch.tenure END as tenure,
		ch."TotalCharges"/CASE WHEN ch.tenure=0 THEN 1 ELSE ch.tenure END as derived_charge
	FROM s_churn ch
	inner join "D_Customer" on "CUS_BKey" = ch."customerID"
	inner join "D_Contract" on "CON_NAME" = ch."Contract"
	inner join "D_Payment_Method" on "PM_NAME" = ch."PaymentMethod";
BEGIN
    FOR prod_record IN product_cur LOOP

-- 		raise notice 'tenure: %', prod_record.tenure;
		
		FOR t IN 1..prod_record.tenure LOOP
-- 			raise notice 'months: %', t;
			INSERT INTO public."F_Charges" (
				"CUS_ID",
				"CON_ID",
				"CHG_Charge",
				"PM_ID",
				"DATE_ID",
				"BM_ID"
			)
			VALUES (
				prod_record."CUS_ID",
				prod_record."CON_ID",
				prod_record.derived_charge,					
				prod_record."PM_ID",
				to_char(now() - interval '1 month' * t, 'YYYYMM')::integer,
				prod_record."BM_ID"
				);
		END LOOP;

    END LOOP;
END$$;
