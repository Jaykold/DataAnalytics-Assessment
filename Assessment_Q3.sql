/*
* Account Inactivity Alert Report
* 
* Purpose: Identify accounts with no inflow transactions in the past year
* to support ops team's dormant account monitoring
*
* This SQL query is designed for MySQL, as the database dump file is formatted for MySQL.
*/

WITH latest_transaction_date AS (
    -- Get the most recent transaction date once to avoid recalculating
    SELECT MAX(transaction_date) AS max_date
    FROM adashi_staging.savings_savingsaccount
    WHERE transaction_status = 'success'
),

last_transactions AS (
    -- Find the most recent inflow transaction for each plan
    SELECT 
        s.plan_id,
        p.owner_id,
        -- Determine account type based on plan flags
        CASE 
            WHEN p.is_regular_savings = 1 THEN 'Savings'
            WHEN p.is_a_fund = 1 THEN 'Investment'
        END AS type,
        MAX(s.transaction_date) AS last_transaction_date
    FROM 
        adashi_staging.plans_plan p
    LEFT JOIN 
        adashi_staging.savings_savingsaccount s ON p.id = s.plan_id
    WHERE 
        -- Filter for active plans
        (p.is_regular_savings = 1 OR p.is_a_fund = 1)
        AND p.is_deleted = 0  -- Exclude deleted plans assuming deleted plans are part of no inflow transactions
        AND s.transaction_status = 'success' -- Only consider successful inflow transactions
        AND s.confirmed_amount > 0  -- Ensure it's an actual inflow with positive amount
    GROUP BY 
        s.plan_id, p.owner_id, type
)

SELECT 
    lt.plan_id,
    lt.owner_id,
    lt.type,
    lt.last_transaction_date,
    -- Calculate inactivity days dynamically using the most current date in the savings table
    DATEDIFF(ltd.max_date, lt.last_transaction_date) AS inactivity_days
FROM 
    last_transactions lt
CROSS JOIN 
    latest_transaction_date ltd  -- Use CROSS JOIN to get the latest transaction date & avoid multiple subqueries
WHERE 
    -- Filter for accounts inactive for more than 365 days
    lt.last_transaction_date < DATE_SUB(ltd.max_date, INTERVAL 365 DAY)
    -- Or accounts with no transaction records
    OR lt.last_transaction_date IS NULL
ORDER BY 
    inactivity_days ASC;