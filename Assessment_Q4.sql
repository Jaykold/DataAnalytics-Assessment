WITH latest_transaction_date AS (
    -- Get the most recent transaction date once to avoid recalculating
    SELECT MAX(transaction_date) AS max_date
    FROM adashi_staging.savings_savingsaccount
    WHERE transaction_status = 'success'
),

customer_transactions AS (
    -- Pre-filter transactions to reduce JOIN complexity
    SELECT 
        owner_id,
        COUNT(id) AS total_transactions,
        SUM(confirmed_amount) AS total_transaction_value
    FROM 
        adashi_staging.savings_savingsaccount
    WHERE 
        transaction_status = 'success'
        AND confirmed_amount > 0
    GROUP BY 
        owner_id
),

customer_tenure AS (
    -- Calculate customer tenure with pre-filtered data
    SELECT 
        u.id AS customer_id,
        CONCAT(u.first_name, ' ', u.last_name) AS name,
        TIMESTAMPDIFF(MONTH, u.date_joined, ltd.max_date) AS tenure_months,
        ct.total_transactions,
        ct.total_transaction_value
    FROM 
        adashi_staging.users_customuser u
    JOIN 
        customer_transactions ct ON u.id = ct.owner_id
    CROSS JOIN
        latest_transaction_date ltd  -- Use CROSS JOIN to get the latest transaction date & avoid multiple subqueries
    WHERE 
        -- Filter out users with insufficient tenure
        u.date_joined <= DATE_SUB(ltd.max_date, INTERVAL 1 MONTH)
)

SELECT 
    customer_id,
    name,
    tenure_months,
    total_transactions,
    ROUND(
        (total_transactions / tenure_months) * 12 * (total_transaction_value * 0.001 / total_transactions),
        2
    ) AS estimated_clv
FROM 
    customer_tenure
WHERE 
    tenure_months > 0
ORDER BY 
    estimated_clv DESC;