select * from information_schema.tables;

create database demo;

select * from upi_transactions;

--1. Display 5 sample transactions
SELECT *
FROM UPI_TRANSACTIONS
LIMIT 5;

--Display the first 20 transactions
SELECT *
FROM UPI_TRANSACTIONS
ORDER BY timestamp
LIMIT 20

--Fetch transactions less than worth 100 INR
SELECT amount_inr, merchant_category
FROM upi_transactions
WHERE amount_inr <100

--How many transactions have happened in total?
select count(*) from upi_transactions

--How many transactions happened in Karnataka?
select count(*) from upi_transactions
where sender_state='Karnataka'

--6.How many transactions happened in July? (2 replies)
select count(*)
from upi_transactions
where month(timestamp) =7

select  count(*) from upi_transactions
where to_char(timestamp,'Mon') = 'Jul'

select count(*)
from upi_transactions
where DATE_PART('month', timestamp) = 7

--7. What is the average value of all transactions?
select avg(amount_inr) from upi_transactions

--8. Display the names of all the banks that initiated the transaction.
select distinct(sender_bank) from upi_transactions

--9. How many unique types of transactions have been used?
select count(distinct transaction_type) from upi_transactions

--10. Identify all the fraudulent transactions on weekends after midnight and before sunrise. Assume sunrise is at 6 a.m.
SELECT *
FROM upi_transactions
WHERE fraud_flag=1 AND  is_weekend=1 AND hour_of_day >=0 AND hour_of_day <6

SELECT *
FROM upi_transactions
WHERE fraud_flag=1 AND  is_weekend=1 AND hour_of_day BETWEEN 0 AND 5
 -- takes all transactions between 12 am and 5.59am.
 
--11. Identify successful transactions initiated by senior citizens. Assume a senior citizen's age starts at 55
SELECT *
FROM UPI_TRANSACTIONS
WHERE TRANSACTION_STATUS = 'SUCCESS' and sender_age_group = '56+'
-- Its impossible to find the users who are exactly 55 years of age, from this data. Data is insufficient for this. 56 and above age users can be found.

--12. How many failed grocery or shopping transactions have happened between midnight and sunrise on weekdays? Assume sunrise is at 5 a.m.
SELECT count(*)
FROM UPI_TRANSACTIONS
WHERE TRANSACTION_STATUS = 'FAILED' AND MERCHANT_CATEGORY IN ('Grocery', 'Shopping') AND IS_WEEKEND =0 AND HOUR_OF_DAY BETWEEN 0 AND 4
--between uses 0 and 4 only, since we need transactions till 4.59 am only. if we use 5, then all transactions till 5.59 will be taken

--13. Identify all transactions involving recharge or bill payments at the SBI bank.
SELECT *
FROM UPI_TRANSACTIONS
WHERE transaction_type IN ('Recharge' , 'Bill Payment')
AND (sender_bank='SBI' OR receiver_bank ='SBI')

--14. Which device type has had the most transactions?
select device_type from upi_transactions group by device_type
order by count(device_type) desc
limit 1

select device_type, count(device_type) as no_of_trans from upi_transactions group by device_type
order by no_of_trans

--2 queries with same results
select distinct device_type
from upi_transactions

select device_type
from upi_transactions
group by device_type

-- Group By creates groups for each unique value for the given column(s). You can then apply aggregate functions to these groups. 
--Aggregate functions in SQl - sum,min,max,count,avg
select device_type, count(device_type), sum(amount_inr), avg(amount_inr)
from upi_transactions
group by device_type

--15. Fetch the total transaction amount per sender bank.
select sender_bank, sum(amount_inr)
from upi_transactions
group by sender_bank
