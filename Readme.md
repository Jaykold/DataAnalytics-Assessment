### Question 1:

#### Explanation:

##### Total Deposits Calculation:

- For investment plans: Use plans_plan.amount from the plans_plan table
- For savings plans: Use savings_savingsaccount.confirmed_amount from the savings_savingsaccount table (assuming this represents the actual deposited amount)
- Added both together for the complete total deposits across both product types

##### Three-Table Join:

- Added the savings_savingsaccount table to get savings-specific deposit information
- Used a LEFT JOIN to the savings table since it only contains data for savings plans

##### Funding Definition:

- Investment plan is funded when plans_plan.amount > 0
- Savings plan is funded when savings_savingsaccount.confirmed_amount > 0

#### Challenges:

- Managing the complex JOIN conditions while maintaining data integrity
- Solution: Used a combination of JOIN and LEFT JOIN with appropriate WHERE conditions to ensure only funded accounts are considered:

```
FROM
    adashi_staging.users_customuser u
JOIN
    adashi_staging.plans_plan p ON u.id = p.owner_id
LEFT JOIN
    adashi_staging.savings_savingsaccount s ON p.id = s.plan_id
WHERE
    (p.is_a_fund = 1 AND p.amount > 0) OR
    (p.is_regular_savings = 1 AND s.confirmed_amount > 0)
```

- The business requirement was to identify customers with multiple active products, but simply checking product flags wasn't sufficient - the products needed to be funded.
- Solution: Used the HAVING clause with conditional counting to ensure customers had both product types with actual deposits:

```
HAVING 
    COUNT(DISTINCT CASE WHEN p.is_regular_savings = 1 AND s.confirmed_amount > 0 THEN p.id END) > 0
    AND 
    COUNT(DISTINCT CASE WHEN p.is_a_fund = 1 AND p.amount > 0 THEN p.id END) > 0
```

### Question 2:

#### Explanation:

##### customer_avg_transactions (CTE 1):

- Calculates the average number of transactions per month for each customer
- This properly handles customers who might have transactions in some months but not others

##### Customer Categorization (CTE 2):

- Applies the business rules to categorize customers:
    - High Frequency: ≥10 transactions/month
    - Medium Frequency: 3-9 transactions/month
    - Low Frequency: ≤2 transactions/month

##### Final Aggregation:

- Counts customers in each frequency category
- Calculates the average transactions per month within each category
- Rounds to one decimal place for readability
- Orders results by frequency category (high to low)

#### Challenges:

- Handling varying transaction periods across customers was complex
- Solution: Used a derived table in CTE 1 with YEAR and MONTH grouping to ensure accurate monthly averages regardless of when customers started transacting:
```
FROM (
        SELECT s.owner_id, YEAR(s.transaction_date) AS year, MONTH(s.transaction_date) AS month, COUNT(*) AS transaction_count
        FROM adashi_staging.savings_savingsaccount s
        WHERE s.transaction_status = 'success'  -- Only count successful transactions
        GROUP BY s.owner_id, year, month
    ) AS monthly_transactions
```

### Question 3:

#### Explanation:

##### Identifying inflow transactions

- Transactions must be successful (transaction_status = 'success')
- Confirmed amount must be positive (confirmed_amount > 0)

##### Active Account Definition:

- Plans are considered active if they're marked as savings (is_regular_savings = 1) or investments (is_a_fund = 1)
- Non-deleted plans only (is_deleted = 0)

##### Inactivity Calculation:

- Using DATEDIFF to calculate days between the last and current date
- Filtering for accounts where this difference exceeds 365 days

##### Ordering:

- Results are ordered by inactivity days (ascending) to prioritize accounts approaching the one-year mark

#### Challenges:

- The original query used a hardcoded current date, which would require manual updates and wouldn't reflect the most recent data available.
Solution:
- Created a dedicated CTE to dynamically determine the latest transaction date

```
WITH latest_transaction_date AS (
    SELECT MAX(transaction_date) AS max_date
    FROM savings_savingsaccount
    WHERE transaction_status = 'success'
)
```
- Managing different account types (savings vs investment) in a single query
- Solution: Used CASE statement to determine account type based on plan flags (is_regular_savings and is_a_fund)

```
CASE 
    WHEN p.is_regular_savings = 1 THEN 'Savings'
    WHEN p.is_a_fund = 1 THEN 'Investment'
    END AS type
```
### Question 4:

#### Explanation:

##### Tenure Calculation:

- Used TIMESTAMPDIFF to find months between signup (date_joined) and most current date in the database
- Ensures accurate month-based calculations regardless of days in each month

##### Transaction Metrics:

- Counted total **successful** transactions per customer
- Calculated total transaction values for profit estimation
- Filtered out zero-value transactions as they don't contribute to profit

##### CLV Formula Implementation:

- Applied the specified formula: CLV = (total_transactions / tenure) * 12 * avg_profit_per_transaction
- Where avg_profit_per_transaction = 0.1% of average transaction value
- Simplified to: (total_transactions / tenure_months) * 12 * (total_transaction_value * 0.001 / total_transactions)
- Rounded to 2 decimal places for currency presentation

#### Challenges:

- The original query used a hardcoded current date, which would require manual updates and wouldn't reflect the most recent data available.

Solution:
- Created a dedicated CTE to dynamically determine the latest transaction date

```
WITH latest_transaction_date AS (
    SELECT MAX(transaction_date) AS max_date
    FROM savings_savingsaccount
    WHERE transaction_status = 'success'
)
```