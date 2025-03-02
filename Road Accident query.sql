--create database Road_accident

use road_accident

--- To rename table
Execute sp_rename 'dbo.Data$', 'Accident_data'

--- Add column name time_of_day
alter table accident_data add Time_of_day varchar(15)

UPDATE accident_data
SET Time_of_day = 
case
	WHEN cast(Time as time) > '00:00:00' and cast(time as time) < '12:00:00' THEN 'Morning'
	WHEN cast(Time as time) >= '12:01:00' and cast(time as time) < '18:00:00' THEN 'Afternoon'
	WHEN cast(time as time) >= '18:00:00' and cast(time as time) < '21:00:00' THEN 'Evening'
	ELSE 'Night'
end
----------------------------------------- START QUERY ---------------------------------------------------
--- Fix data (In Accident_Severity has 'Fetal' value, replace it to 'Fatal'

UPDATE Accident_data
SET Accident_Severity = 'Fatal'
WHERE Accident_Severity = 'Fetal'


--- Count the total number of accidents by level
SELECT
	Accident_Severity Severity,
	FORMAT(COUNT(Accident_Index),'N0') Number_Accident
FROM Accident_data
GROUP BY Accident_Severity
ORDER BY COUNT(Accident_Index) DESC;

--- Identify the number of accidents by vehicle type
SELECT
	Vehicle_Type,
	FORMAT(COUNT(Accident_Index),'N0') Number_Accident
FROM Accident_data
GROUP BY Vehicle_Type
ORDER BY COUNT(Accident_Index) DESC;


--- Calculate the % change in the number of accidents compared to the previous month
WITH Table1 as
(SELECT 
	YEAR([accident date]) Year,
	MONTH([accident date]) Month,
	FORMAT([accident date], 'MMM') Month_text,
	COUNT(accident_index) Cur_Number_accident,
	LAG(COUNT(accident_index)) OVER (PARTITION BY YEAR([accident date]) ORDER BY MONTH([accident date])) Pre_Number_accident
FROM accident_data
GROUP BY Year([accident date]), Month([accident date]), FORMAT([accident date], 'MMM')
)
SELECT 
	Year, Month_text as Month,
	Cur_Number_accident Number_Accident,
	FORMAT(ISNULL((Cur_Number_accident - Pre_Number_accident)/ CAST(Pre_Number_accident as DECIMAL(10,2)),0),'P2') '% Change'
FROM Table1;

--- Determine the number of accidents based on TOP 3 types of vehicles  at different times of the day
WITH Table1 as
	(SELECT 
		MONTH([Accident Date]) Month_Num,
		DATENAME(MONTH, [Accident Date]) Month_text,
		Time_of_day,
		FORMAT(COUNT(Accident_Index), 'N0') Number_Accident,
		RANK() OVER (PARTITION BY Time_of_day ORDER BY COUNT(Accident_Index) DESC) Rank
	FROM Accident_data
	GROUP BY MONTH([Accident Date]), Time_of_day, DATENAME(MONTH, [Accident Date]))
-----
SELECT
	Month_text,
	Time_of_day,
	Number_Accident
FROM Table1
WHERE Rank <= 3


---- Calculate number of Accident follow YoY
--- THE FIRST METHOD
WITH table1 as 
(SELECT
	year([Accident Date]) Year,
	FORMAT([accident date], 'MMM') Month,
	cast(count(accident_index) as decimal(10,2)) Number_Accident,
	cast(sum(Number_of_Casualties) as decimal(10,2)) Total_Casuality,
	month([Accident Date]) Month_Num
FROM Accident_data
GROUP BY Year([Accident Date]), FORMAT([accident date], 'MMM'), month([Accident Date])),
--ORDER BY year asc, Month([Accident Date]) asc),
table2 as
(SELECT 
	Year, Month, Month_Num, Number_Accident, Total_Casuality
FROM table1 WHERE Year = 2021),
table3 as 
(SELECT 
	year, Month, Number_Accident, Total_Casuality
FROM table1 WHERE year = 2022)

SELECT t2.Month,
	t3.Year Year,
	FORMAT((t3.Number_Accident - t2.Number_Accident)/t2.Number_Accident, 'p') 
	as YoY_Accidents,
	cast(cast(((t3.Total_Casuality - t2.Total_Casuality)/t2.Total_Casuality)*100 as decimal(5,2)) as varchar(10))+'%' 
	as YoY_Accidents
FROM table2 as t2 
join table3 as t3 ON t2.Month = t3.Month
ORDER BY Month_Num asc;

--- THE SECOND METHOD
WITH Table1 as
(SELECT 
	Year([accident date]) Year,
	Month([accident date]) Month,
	FORMAT([accident date], 'MMM') Month_text,
	COUNT(accident_index) Number_accident
FROM accident_data
GROUP BY Year([accident date]), Month([accident date]), FORMAT([accident date], 'MMM'))
---
SELECT 
	cur.Year, 
	cur.Month,
	cur.Number_accident Current_year,
	pre.Number_accident Previous_year,
	cur.Number_accident - pre.Number_accident Difference,
	FORMAT((cur.Number_accident - pre.Number_accident)/CAST(pre.Number_accident as DECIMAL(10,2)),'P2') '% Difference'
FROM Table1 as cur
JOIN Table1 as pre ON cur.year = pre.Year + 1  AND cur.Month = pre.Month
ORDER BY Year asc, Month asc


--- Accumulate follow month in each years

;WITH table1 as
(SELECT 
	year([Accident Date]) Year,
	FORMAT([accident date],'MMM') Month_text,
	Month([accident date]) Month,
	SUM(Number_of_Casualties) Total
FROM Accident_data
GROUP BY year([accident date]), FORMAT([accident date], 'MMM'), month([accident date]))
----
SELECT 
	Year, Month_text,
	total,
	sum(total) OVER ( PARTITION BY YEAR	ORDER BY year asc, month asc) Accumulated
FROM table1 
