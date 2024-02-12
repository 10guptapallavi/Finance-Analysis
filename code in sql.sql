--Check our data 
Select * FROM projects.dbo.Budget
SELECT * FROM projects.dbo.personal_transactions


--Number of records 
SELECT Count(*) 'Number of records in Budget Table' FROM projects.dbo.Budget
SELECT Count(*) 'Number of records in Personal Transaction Table'FROM projects.dbo.personal_transactions

-- Daily transactions 
SELECT date, SUM(Amount) As 'total daily expenditure'
From projects.dbo.personal_transactions
WHERE Transaction_Type = 'debit' 
group by date

--to get more realistic data, check montly expenditure
SELECT Month(date) Month, 
	SUM(CASE WHEN YEAR(date) ='2018' THEN Amount  END) as 'total monthly expenditure (2018)',
	SUM(CASE WHEN YEAR(date) ='2019' THEN amount  END) as 'total montly expenditure (2019)'
FROM projects.dbo.personal_transactions
WHERE Transaction_Type = 'debit' 
GROUP BY Month(date)

---calculate total budget alloted each month
Select SUM(budget) 'total budget'
from  projects.dbo.Budget
--monthly income
SELECT Month(date) Month, 
	SUM(CASE WHEN YEAR(date) ='2018' THEN Amount  END) as 'total budget (2018)',
	SUM(CASE WHEN YEAR(date) ='2019' THEN amount  END) as 'total budget (2019)'
FROM projects.dbo.personal_transactions
WHERE category = 'paycheck' 
GROUP BY Month(date)
--to check null values checktable again
Select Distinct(Category) From projects.dbo.personal_transactions
--october, november and december data of 2019 is unavailable


---- Finding total number of categories 
SELECT DISTINCT
	pt.[Category] as pt, b.[Category] as b
FROM projects.dbo.personal_transactions pt
left join projects.dbo.Budget b
On   pt. [Category]= b.[Category]

SELECT  Year(date) year, 
	SUM(amount) 'total money spent '
FROM projects.dbo.personal_transactions
WHERE Transaction_Type = 'debit' 
GROUP BY Year(date)

--Category wise expenditute from 2018-september 2019
SELECT Category,max(amount) 'maximum exp',
	min(Amount) 'minimum amt',
	avg(amount) ' average exp',
	sum(amount) 'total exp in this category'
FROM projects.dbo.personal_transactions
WHERE Transaction_Type = 'debit' 
GROUP BY category
Order by SUM(amount) DESC

SELECT Top(5) Category, 
	Amount, 
	Year(Date) AS 'Year', 
	Month(Date) AS 'Month'
FROM projects.dbo.personal_transactions
WHERE Transaction_Type = 'debit' AND Category != 'Credit Card Payment'
ORDER BY Amount DESC




SELECT Month(date) As 'month',
	SUM(CASE WHEN YEAR(DATE) ='2018' THEN Amount END) 'Spending By Month(2018)', 
	SUM(CASE WHEN YEAR(DATE) ='2019' THEN Amount END) 'Spending By Month(2019)'
FROM projects.dbo.personal_transactions
WHERE Transaction_Type = 'debit' And Account_Name ='checking' 
GROUP BY Month(date)
ORDER BY Month(date)
SELECT  Account_Name,
		SUM(Amount) 'Spending By Account'
FROM projects.dbo.personal_transactions
WHERE Transaction_Type = 'debit'  
GROUP BY Account_Name
-- Income versus spending by month
SELECT  
	 Month(date) As 'month',
		Year(date) AS 'Year',
	SUM(CASE WHEN Transaction_Type = 'debit' THEN Amount ELSE 0 END) As 'Spending By Month', 
		SUM(CASE WHEN Category = 'Paycheck' THEN Amount ELSE 0 END) As 'Income',
		SUM(CASE WHEN Category = 'Paycheck' THEN Amount ELSE 0 END)-SUM(CASE WHEN Transaction_Type = 'debit' THEN Amount ELSE 0 END) As 'Monthly Saving',
		SUM(CASE WHEN Transaction_Type = 'debit' THEN Amount ELSE 0 END)/ SUM(CASE WHEN Category = 'Paycheck' THEN Amount ELSE 0 END) *100 AS 'Percentage of income spent'
FROM  projects.dbo.personal_transactions
WHERE Account_Name ='checking' 
GROUP BY   Month(date), YEAR(Date)
ORDER BY YEAR(Date), Month(date)

-- yearly Spending by Category  

SELECT SUM(Amount) 'Spending By Category', 
	Category, 
	YEAR(Date) AS Year
FROM projects.dbo.personal_transactions
WHERE Transaction_Type = 'debit'
GROUP BY Category, YEAR(date)
ORDER BY YEAR(date), SUM(Amount) DESC
-- monthly  Spending by Category  
SELECT Category, SUM(Amount) 'Spending By Category', 
	Month (Date) AS Month,
	year(Date) as year
FROM projects.dbo.personal_transactions
WHERE Transaction_Type = 'debit'
GROUP BY Category, month(date), year(date)
ORDER BY month(date), SUM(Amount) DESC

--Top Five most spent on categories in years 2018 and 2019

SELECT TOP(5) Category, 
	SUM(Amount) 'Spending By Category' 
FROM projects.dbo.personal_transactions
WHERE Transaction_Type = 'debit'
GROUP BY Category
ORDER BY SUM(Amount) DESC

-- category wise monthly Spending compared to the budget 

SELECT A.*,
	b.maxval,
	b.minval,
	sum(A.[Spending By Category]) over (Partition by A.Category Order by A.Year , A.Month) 'Running Total'
FROM
	(
	SELECT P.Category,
		MONTH(Date) AS Month,
		YEAR(Date) AS Year,
		SUM(P.Amount) 'Spending By Category',
		COUNT(*) 'total transactions', B.Budget,
		Case when B.Budget!=0 then (SUM(P.Amount)/B.Budget)*100 else SUM(P.Amount)  end 'Percentage of Budget used'
	FROM projects.dbo.personal_transactions As P
	Inner JOIN   projects.dbo.Budget AS B
	ON P.Category = B.Category 
	WHERE Transaction_Type = 'debit' AND P.Category != 'Credit Card Payment'
	GROUP BY P.Category, Month(date), Year(date), B.Budget
	)A
	inner join (
	SELECT Category, max(amount) maxval, 
			min(Amount) minval
	FROM projects.dbo.personal_transactions
	GROUP BY category)b 
ON a.Category =b.Category
--WHERE A.[Percentage of Budget Used]>100
ORDER BY YEAR, Month, Budget Desc


--Categories that have outspent budget

SELECT Z.Category,
	COUNT(*) 'Number of times outspent' , 
	MAX(Z.[Spending By Category])'Maximum Spent', 
	Max(Z.Budget)Budget
FROM
(
SELECT A.*,b.maxval,b.minval,
	sum(A.[Spending By Category]) over (Partition by A.Category Order by A.Year , A.Month) 'Running Total',
	Row_Number() OVER (Partition by a.Category ORDER BY a.[Spending By Category] DESC) AS Rank
FROM
(
SELECT P.Category,
	MONTH(Date) AS Month,
	YEAR(Date) AS Year,
	SUM(P.Amount) 'Spending By Category',
	COUNT(*) 'total transactions', B.Budget, 
	Case when B.Budget!=0 then (SUM(P.Amount)/B.Budget)*100 end 'Percentage of Budget used'
FROM projects.dbo.personal_transactions As P
Inner JOIN  projects.dbo.Budget  AS B
ON P.Category = B.Category 
WHERE Transaction_Type = 'debit' AND P.Category != 'Credit Card Payment'
GROUP BY P.Category, Month(date), Year(date),  B.Budget
)A
inner join (SELECT max(amount) maxval, min(Amount) minval,Category
			FROM projects.dbo.personal_transactions
			GROUP BY category)b 
ON a.Category =b.Category
)z
WHERE  Z.[Percentage of Budget used]>100
GROUP BY Z.Category
Order BY  COUNT(*)DESC