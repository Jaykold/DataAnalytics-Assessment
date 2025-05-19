/*
* Transaction Frequency Analysis Query 
*
* Purpose: Analyze and segment customers based on their transaction frequency
* to support finance team's customer segmentation initiative

* This SQL query is designed for MySQL, as the database dump file is formatted for MySQL.
*/


WITH customer_avg_transactions AS (
    -- Calculate average transactions per month for each customer
    -- AVG function automatically handles customers with varying activity periods
    SELECT
        owner_id,
        AVG(transaction_count) as avg_transactions_per_month
    FROM (
        -- Subquery that counts successful transactions per customer per month-year combination
        -- This ensures we don't mix transactions from the same month across different years
        SELECT 
            s.owner_id,
            YEAR(s.transaction_date) AS year,
            MONTH(s.transaction_date) AS month,
            COUNT(*) AS transaction_count
        FROM 
            adashi_staging.savings_savingsaccount s
        WHERE 
            s.transaction_status = 'success'  -- Only count successful transactions
        GROUP BY 
            s.owner_id, year, month
    ) AS monthly_transactions
    GROUP BY 
        owner_id
),

categorized_customers AS (
    -- Second CTE: Categorize customers based on business-defined frequency thresholds
    SELECT 
        CASE 
            WHEN avg_transactions_per_month >= 10 THEN 'High Frequency'
            WHEN avg_transactions_per_month >= 3 THEN 'Medium Frequency'
            ELSE 'Low Frequency'
        END AS frequency_category,
        avg_transactions_per_month
    FROM 
        customer_avg_transactions
)

-- Final query: Summarize customer counts and average transactions by frequency category
SELECT 
    frequency_category,
    COUNT(*) AS customer_count,
    ROUND(AVG(avg_transactions_per_month), 1) AS avg_transactions_per_month
FROM 
    categorized_customers
GROUP BY 
    frequency_category
ORDER BY 
    CASE 
        WHEN frequency_category = 'High Frequency' THEN 1
        WHEN frequency_category = 'Medium Frequency' THEN 2
        ELSE 3
    END;