-- This query is to validate that migrated claims are closed in WKAB

WITH ALL_DATA AS (
SELECT 
       --T_DIS_PLAN_VERSION.POLICY_NUM AS PLCY_NBR,
       T_ACCOUNT_STRUCTURE.CONTROL_NUMBER AS CONTROL_NUMBER, 
       --*********************************************************************
       T_ACCOUNT_STRUCTURE.CUSTOMER_NUMBER AS CUSTOMER_NUMBER,  
       T_ACCOUNT_STRUCTURE.COMPANY_ID AS COMPANY_ID,  
       T_COMPANY_TAS.COMPANY_NAME     AS COMPANY_NAME,  
       T_DIS_PLAN_VERSION.CARRIER, 
       T_PW_CLAIM.CLAIM_ID AS PW_CLAIM_ID,
       T_PW_CLAIM.MSTR_CLAIM_ID,
       T_PW_MSTR_CLAIM.MIGR_DT AS MIGR_DT,
       NVL(T_DIS_PLAN.ERISA_PLAN_ADMINISTRATOR, NVL(EXP_BIC.CODE_VALUE,'99999999')) AS EXP_BIC_CD, --added 7/17 --added NVL 7/27
       ASO_FI.CODE_VALUE FUNDING_METHOD, --added 7/27
       CASE
          WHEN L.CODE_VALUE IN
                  ('BASIC', 'BISPTD', 'WSAL', 'BASIC', 'GPER', 'GPTM')
          THEN
             'BTRM'
          WHEN L.CODE_VALUE IN ('SUPP', 'SISPTD')
          THEN
             'STRM'
          WHEN L.CODE_VALUE IN
                  ('PUP',
                   'GAC1',
                   'SIB1',
                   'SIB2',
                   'SIBUF',
                   'SIBMF',
                   'PUP2',
                   'PUP3',
                   'GUL1')
          THEN
             'VOL'
          ELSE
             'BTRM'
       -- Need to retain the original Cov Type for Batch Run
       --ELSE NVL (L.CODE_VALUE, T_PW_CLAIM.CLAIM_CAT_LID)
       END
          AS COV_TYP_CD,
       --NVL (L.CODE_VALUE, T_PW_CLAIM.CLAIM_CAT_LID) WKAB_COV_TYPE,
       --Added 10/3 to use the EXP_BIC if the CLAIM_CAT_LID is not valid
       --instead of using the code, which is useless
       --The third from last position in the EXP_BIC determines Basic or Supp
       -- 2 is Supp
       CASE
         WHEN L.CODE_VALUE IS NULL THEN
           CASE
             WHEN SUBSTR(EXP_BIC.CODE_VALUE,-3,1) = '2'
             THEN 'SUPP'
             ELSE 'BASIC'
           END
         ELSE L.CODE_VALUE 
       END WKAB_COV_TYPE, 
       --T_PW_CLAIM.CLAIM_ID AS PW_CLM_CVRG_ID,
       --'DIRCT' AS BSNSS_SGMNT_CD,
       CASE
          WHEN T_PW_DETERMINATION.STATUS_LID = 773503 --Terminated
          THEN
             T_PW_DETERMINATION.CREATE_DATE
          ELSE
             NULL
       END
          AS CLM_STTS_EFFCTV_DT,
       T_PW_DETERMINATION.STATUS_LID, 
       --*********************************************************************
       --**  Translation to HIG Status Code
       CASE
          WHEN CS.CODE_VALUE = 'PEND' THEN '01'
          WHEN CS.CODE_VALUE = 'APPROVED' THEN '02'
          WHEN CS.CODE_VALUE = 'DENIED' THEN '03'
          WHEN CS.CODE_VALUE = 'TERMINATE' THEN '04'
          WHEN CS.CODE_VALUE = 'TRANSITIONED' THEN '04'
          --WHEN CS.CODE_VALUE = 'CANCELLED' THEN '04'
          WHEN CS.CODE_VALUE = 'CANCELLED' THEN '03' --change cancelled to denied
          WHEN CS.CODE_VALUE = 'CLOSURE' THEN '03' --changed closure to denied (was 04)
          ELSE '01'
       END
          AS CLM_STTS_CD,
       --*********************************************************************
       -- Term Reason Mapping
       CASE
          WHEN T_PW_DETERMINATION.STATUS_LID IN (773500, 773501) THEN NULL 
          ELSE RC.CODE_VALUE
       END
          AS CLAIM_STATUS_REASON_WKAB, 
       CASE 
         WHEN T_PW_DETERMINATION.STATUS_LID IN (773500, 773501) THEN NULL --Pend or Approve
         WHEN RC.CODE_VALUE IN ('CLAIMWITHDRAWN','CLAIMWITHDRAWNDENY') THEN 'B5' --CLAIM WITHDRAWN
         WHEN RC.CODE_VALUE IN ('DEATHDENY') THEN '8' --DEATH OF CLAIMANT for Deny
         WHEN RC.CODE_VALUE IN ('DEATHTERMINATE') THEN '54' --CONVERTED TO DEATH for Terminate  -- changed to 54 10/2/18
         WHEN RC.CODE_VALUE IN ('MAXBENEFITS','RETIREMENTDENY') THEN '7' --BENEFITS EXPIRE
         WHEN RC.CODE_VALUE IN ('PLANSPONSOR','PLANSPONSORCANC') THEN 'A2' --DISABILITY DATE AFTER POLICY CANCELLATION DATE
         WHEN RC.CODE_VALUE = 'LATEFILE' THEN '65' --PREMIUM WAIVER LATE NOTICE
         WHEN RC.CODE_VALUE = 'OVERAGEDENY' THEN 'E9' --DENIED - SEAMLESS OTA REPORT ERROR
         WHEN RC.CODE_VALUE = 'NOLONGERSUPPORT' THEN '11' --NO LONGER MEETS DEFINITION OF DISABILITY
         ELSE
           CASE
             WHEN T_PW_DETERMINATION.STATUS_LID IN (773502,773505,773506) --Denied/Cancelled/Closure
             THEN
               CASE
                 WHEN RC.CODE_VALUE IN ('RELEASETORTWDENY','RTWFTDENY','RTWPTDENY','RTWFT') THEN '98' --RETURNED TO WORK - Denied
                 WHEN RC.CODE_VALUE IN ('NONCOMPLIANCEDENY') THEN 'A1' --DENIED - LACK OF RESPONSE
                 WHEN RC.CODE_VALUE IN ('ENTEREDINERROR') THEN '27' --ENTERED IN ERROR - Denied
                 WHEN RC.CODE_VALUE IN ('MAXAGE') THEN '19' --CLAIMANT EXCEEDS LIMITING AGE AND IS NOT COVERED
                 WHEN RC.CODE_VALUE LIKE ('INITIALDEATHNOTICE%') THEN '8' --DEATH OF CLAIMANT for Deny
                 WHEN RC.CODE_VALUE IN ('NOCOVERAGECLOSURE') THEN '45' --NO PREMIUM WAIVER COVERAGE
                 WHEN RC.CODE_VALUE IN ('OVERAGE') THEN '19' --CLAIMANT EXCEEDS LIMITING AGE AND IS NOT COVERED
                 ELSE '16' --OTHER
               END
             ELSE --Terminated
               CASE
                 WHEN RC.CODE_VALUE IN ('RTWFTTERMINATE','RTWPT','RTWFT') THEN '06' --RETURNED TO WORK - Terminate
                 WHEN RC.CODE_VALUE IN ('RELEASETORTW') THEN '35' --RELEASED TO RETURN TO WORK
                 WHEN RC.CODE_VALUE IN ('NONCOMPLIANCE') THEN 'D1' --LACK OF RESPONSE - Terminate
                 WHEN RC.CODE_VALUE IN ('ENTEREDINERROR') THEN '60' --ENTERED IN ERROR - Terminate
                 WHEN RC.CODE_VALUE IN ('MAXAGE') THEN 'D2' --AGE LIMIT REACHED - INSURED
                 WHEN RC.CODE_VALUE LIKE ('INITIALDEATHNOTICE%') THEN '54' --CONVERTED TO DEATH -- changed to 54 10/2/18
                 ELSE '16' --OTHER
               END
             END         
       END
         AS CLAIM_STATUS_REASON_CODE,
       T_PW_MSTR_CLAIM.DISABILITY_DATE
          Date_of_Disability,
       NVL (T_EMPLOYEE.DOB, TO_DATE ('01/01/1901', 'MM/DD/YYYY'))
          AS BIRTH_DT,
       CASE
          WHEN T_PERSON.GENDER_ID = 1 THEN 'F'
          WHEN T_PERSON.GENDER_ID = 2 THEN 'M'
          ELSE 'O'
       END
          AS SEX_CD,
       --Added 3 values below in order to be able to match with NVS
       LPAD(TO_CHAR(T_PERSON.SSN),9,0)                AS SSNBR,
       RTRIM(SUBSTR(T_PERSON.LAST_NAME,1,25))         AS LAST_NAME, --Level I
       RTRIM(SUBSTR(T_PERSON.FIRST_NAME,1,20))        AS FIRST_NAME,
       T_PW_MSTR_CLAIM.CREATE_DATE
          AS FIRST_REPORTED_DATE,
       T_PW_CLAIM.ORIGINAL_AMT AS BNFT_AMT,
       T_PW_CLAIM.CLAIM_EFF_DATE AS BNFT_EFFCTV_DT,
       BEN_ENDDT.BENEFIT_SCHEDULE_DATE AS BNFT_END_DT,        
       T_PW_CLAIM.HIERARCHY_NO, --added 8/27 for ranking
-- More fields added
       T_ACCOUNT_STRUCTURE.ACCOUNT_STRUCTURE_ID       AS ACCOUNT_STRUCTURE_ID,  --not for What-If, analysis only --added 11/29/18
       T_ACCOUNT_STRUCTURE.SUFFIX                     AS SUFFIX,  --not for What-If, analysis only --added 11/29/18
       T_ACCOUNT_STRUCTURE.ACCOUNT_NO                 AS ACCOUNT_NO,  --not for What-If, analysis only --added 11/29/18
--       T_ACCOUNT_STRUCTURE.LOSS_UNIT_NUM              AS LOSS_UNIT_NUM,  --not for What-If, analysis only --added 11/29/18
       TO_CHAR(T_ACCOUNT_STRUCTURE.CSA_START_DATE,'MM/DD/YYYY')
                                                      AS CSA_START_DATE,  --not for What-If, analysis only --added 11/29/18
--Additional fields needed for WARP -- J Caruk 1/11/19
       T_EMPLOYEE.EMP_STATUS_CODE                     AS EMP_STATUS_CODE,
       T_EMPLOYEE.PERSON_ID                           AS PERSON_ID,
       T_ACCOUNT_STRUCTURE.PLAN_SUMMARY               AS PLAN_SUMMARY,
       T_ACCOUNT_STRUCTURE.PLAN_NUMBER                AS PLAN_NUMBER,
       T_COMPANY_PARMS.PARM_NAME

  --**********************************************************************--
  FROM WKAB10.T_PW_CLAIM T_PW_CLAIM
       INNER JOIN WKAB10.T_PW_MSTR_CLAIM T_PW_MSTR_CLAIM
          ON T_PW_MSTR_CLAIM.CLAIM_ID = T_PW_CLAIM.MSTR_CLAIM_ID
       INNER JOIN WKAB10.T_PW_DETERMINATION T_PW_DETERMINATION
          ON     T_PW_DETERMINATION.CLAIM_ID = T_PW_CLAIM.CLAIM_ID
             AND T_PW_DETERMINATION.PW_DETERMINATION_ID IN --also get max id to prevent dups, 7/27/18 JC
                    (SELECT MAX (PW_DETERMINATION_ID)  
                       FROM WKAB10.T_PW_DETERMINATION T
                      WHERE T.CLAIM_ID = T_PW_DETERMINATION.CLAIM_ID
                        AND T.CREATE_DATE IN 
                            (SELECT MAX (CREATE_DATE)
                               FROM WKAB10.T_PW_DETERMINATION T2
                              WHERE T.CLAIM_ID = T2.CLAIM_ID))
       --First Approval Date
       LEFT OUTER JOIN 
             (SELECT CLAIM_ID, MIN (CREATE_DATE) FIRST_APPRV_DT
               FROM WKAB10.T_PW_DETERMINATION 
               WHERE T_PW_DETERMINATION.STATUS_LID = 773501
               GROUP BY CLAIM_ID) T_PW_DETERMINATION_MIN
             ON T_PW_DETERMINATION_MIN.CLAIM_ID = T_PW_CLAIM.CLAIM_ID
       --Date of Birth
       LEFT OUTER JOIN WKAB10.T_EMPLOYEE T_EMPLOYEE
          ON T_PW_CLAIM.EMPLOYEE_ID = T_EMPLOYEE.EMPLOYEE_ID
       -- Gender/Name
       LEFT OUTER JOIN WKAB10.T_PERSON T_PERSON
          ON T_EMPLOYEE.PERSON_ID = T_PERSON.PERSON_ID
       --Coverage Category Code
       LEFT OUTER JOIN WKAB10.T_WKAB_LOOKUP L
          ON T_PW_CLAIM.CLAIM_CAT_LID = L.LOOKUP_ID
       --             AND L.CODE_TYPE = 'PW_CLAIM_CAT'
       LEFT OUTER JOIN WKAB10.T_WKAB_LOOKUP WP
          ON T_PW_CLAIM.WAITING_PERIOD_TYPE_LID = WP.LOOKUP_ID
       --             AND WP.CODE_TYPE = 'TIME_UNIT'
       --Claim Status
       LEFT OUTER JOIN WKAB10.T_WKAB_LOOKUP CS
          ON T_PW_DETERMINATION.STATUS_LID = CS.LOOKUP_ID
       --             AND CS.CODE_TYPE = 'PW_DETERMINE_STATUS'
       --Reason
       LEFT OUTER JOIN WKAB10.T_WKAB_LOOKUP RC
          ON RC.LOOKUP_ID = T_PW_DETERMINATION.REASON_LID
       --             AND RC.CODE_TYPE = 'PW_DETERMINE_REASON'
       --Look for the Migrated company parameter
       LEFT OUTER JOIN WKAB10.T_DIS_PLAN_VERSION T_DIS_PLAN_VERSION
          ON T_DIS_PLAN_VERSION.VERSION_ID = T_PW_CLAIM.VERSION_ID
       LEFT OUTER JOIN WKAB10.T_DIS_PLAN T_DIS_PLAN
          ON T_DIS_PLAN.PLAN_ID = T_DIS_PLAN_VERSION.PLAN_ID
       LEFT OUTER JOIN WKAB10.T_COMPANY T_COMPANY
          ON T_COMPANY.COMPANY_ID = T_DIS_PLAN.COMPANY_ID
       LEFT OUTER JOIN WKAB10.T_COMPANY_PARMS T_COMPANY_PARMS
          ON     T_COMPANY_PARMS.COMPANY_ID = T_DIS_PLAN.COMPANY_ID
             AND T_COMPANY_PARMS.PARM_CATEGORY = 'Client Configuration'
             AND T_COMPANY_PARMS.PARM_NAME = 'NEWCO'
--       LEFT OUTER JOIN WKAB10.T_WKAB_LOOKUP SGT
--          ON SGT.LOOKUP_ID = T_COMPANY_PARMS.COMPANY_PARMS_ID
       --             AND SGT.CODE_TYPE IN ('EB_MARKET_CAT')
       --JC 7/17/2018 --EXP BIC
       LEFT OUTER JOIN WKAB10.T_WKAB_LOOKUP EXP_BIC
          ON EXP_BIC.LOOKUP_ID = T_DIS_PLAN_VERSION.BENEFIT_IDENTIFICATION_CODE_ID
       --JC 7/27/2018
       LEFT OUTER JOIN WKAB10.T_WKAB_LOOKUP ASO_FI
          ON ASO_FI.LOOKUP_ID = T_DIS_PLAN_VERSION.ASO_INSURED_ID
       --Control Number - JC 6/5/18
       LEFT OUTER JOIN WKAB10.T_ACCOUNT_STRUCTURE
          ON T_PW_CLAIM.ACCOUNT_STRUCTURE_ID = T_ACCOUNT_STRUCTURE.ACCOUNT_STRUCTURE_ID
       --Benefit End Date
       --Added by Julia 7/17/18
       LEFT OUTER JOIN (  SELECT B.CLAIM_ID, B.BENEFIT_SCHEDULE_DATE
                          FROM WKAB10.T_BENEFIT_SCHEDULE B
                          WHERE B.BENEFIT_SCHED_ID IN 
                                     (SELECT MAX(B2.BENEFIT_SCHED_ID)
                                      FROM WKAB10.T_BENEFIT_SCHEDULE B2
                                      WHERE B.CLAIM_ID = B2.CLAIM_ID
                                      AND B2.REDUCE_AMT = 0)
                          AND B.REDUCE_AMT = 0 ) BEN_ENDDT
          ON T_PW_CLAIM.CLAIM_ID = BEN_ENDDT.CLAIM_ID              
       LEFT OUTER JOIN WKAB10.T_COMPANY T_COMPANY_TAS
          ON T_ACCOUNT_STRUCTURE.COMPANY_ID = T_COMPANY_TAS.COMPANY_ID    

)
SELECT AD.* 
FROM ALL_DATA AD
WHERE PARM_NAME = 'NEWCO' --only the migrated companies
AND CLM_STTS_CD IN ('01','02')
;
