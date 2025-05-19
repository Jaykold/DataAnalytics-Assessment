/*
* Multi-Product High-Value Customers Analysis
* 
* Purpose: Identify customers who have both regular savings and investment accounts
* with actual deposits to support cross-selling and customer relationship analysis
*
* This SQL query is designed for MySQL, as the database dump file is formatted for MySQL.
*/

SELECT 
    u.id AS owner_id,
    CONCAT(u.first_name, ' ', u.last_name) AS name,
    -- Count distinct plans for each product type
    COUNT(DISTINCT CASE WHEN p.is_regular_savings = 1 THEN p.id END) AS savings_count,
    COUNT(DISTINCT CASE WHEN p.is_a_fund = 1 THEN p.id END) AS investment_count,
    -- Calculate total deposits by summing both product types
    ROUND(
        SUM(CASE WHEN p.is_a_fund = 1 THEN p.amount ELSE 0 END) +
        SUM(CASE WHEN p.is_regular_savings = 1 THEN s.confirmed_amount ELSE 0 END),
    0) AS total_deposits
FROM
    adashi_staging.users_customuser u
JOIN
    adashi_staging.plans_plan p ON u.id = p.owner_id
LEFT JOIN
    adashi_staging.savings_savingsaccount s ON p.id = s.plan_id
WHERE
    -- Filter for funded accounts only
    (p.is_a_fund = 1 AND p.amount > 0) OR
    (p.is_regular_savings = 1 AND s.confirmed_amount > 0)
GROUP BY
    u.id, name
HAVING
    -- Ensure customer has both product types with actual deposits
    COUNT(DISTINCT CASE WHEN p.is_regular_savings = 1 AND s.confirmed_amount > 0 THEN p.id END) > 0
    AND
    COUNT(DISTINCT CASE WHEN p.is_a_fund = 1 AND p.amount > 0 THEN p.id END) > 0
ORDER BY
    total_deposits DESC;