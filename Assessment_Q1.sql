/*
* This SQL query retrieves a list of users who have both regular savings accounts and investment accounts.
* It calculates the total deposits made by each user in both types of accounts and orders the results by total deposits in descending order.

* This SQL query is designed for MySQL, as the database dump file is formatted for MySQL.

*/

SELECT 
    u.id AS owner_id,
    CONCAT(u.first_name, ' ', u.last_name) AS name,
    COUNT(DISTINCT CASE WHEN p.is_regular_savings = 1 THEN p.id END) AS savings_count,
    COUNT(DISTINCT CASE WHEN p.is_a_fund = 1 THEN p.id END) AS investment_count,
    ROUND(
        COALESCE(SUM(CASE WHEN p.is_a_fund = 1 THEN p.amount ELSE 0 END), 0) +
        COALESCE(SUM(CASE WHEN p.is_regular_savings = 1 THEN s.confirmed_amount ELSE 0 END), 0),
    0) AS total_deposits
FROM
    adashi_staging.users_customuser u
JOIN
    adashi_staging.plans_plan p ON u.id = p.owner_id
LEFT JOIN
    adashi_staging.savings_savingsaccount s ON p.id = s.plan_id
WHERE
    (p.is_a_fund = 1 AND p.amount > 0) OR
    (p.is_regular_savings = 1 AND s.confirmed_amount > 0)
GROUP BY
    u.id, name
HAVING
    COUNT(DISTINCT CASE WHEN p.is_regular_savings = 1 AND s.confirmed_amount > 0 THEN p.id END) > 0
    AND
    COUNT(DISTINCT CASE WHEN p.is_a_fund = 1 AND p.amount > 0 THEN p.id END) > 0
ORDER BY
    total_deposits DESC;