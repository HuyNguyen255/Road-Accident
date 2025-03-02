# Road Accident Analysis (Phân tích tình hình vụ va chạm giao thông)

## Introduction (Giới thiệu) 📚

Nhằm mục đích để phân tích 📊 dữ liệu những vụ va chạm giao thông ở nước Anh. Quan đó giúp chúng ta hiểu được phần nào về số vụ tai nạn giao thông ở đất nước trên

## Problems (Vấn đề) ⁉️

### **Những vấn đề (yêu cầu) 🔍 về việc phân tích hoạt động kinh doanh của quán:**

1. Tìm ra tổng số vụ va chạm theo mức độ nghiêm trọng.
2. Tính số lượng vụ va chạm tính theo lượng phương tiện giao thông
3. Tính phần trăm thay đổi trong số vụ va chạm so với tháng liên trước đó
4. Xác định TOP 3 loại phương tiên giao thông có số lượng va chạm nhiều nhất theo từng khung thời gian trong ngày
5. Tính lũy kế cộng dồn số vụ va chạm theo thời gian
6. Xác định sự tăng hoặc giảm số lượng vụ va chạm của năm hiện tại (2022) so với năm trước đó (2021)

## Tool I Used (Những công cụ sử dụng trong bài phân tích này) 🛠️

- **SQL Server:** Dùng để truy vấn (query)

- **Power BI:** Trực quan hóa dữ liệu thông qua dữ liệu bằng bảng, biểu đồ thông qua file truy vấn 

- **Github:** Đăng những câu truy vấn, file dữ liệu cũng như file trực quan hóa dữ liệu để chia sẻ cho mọi người và bài phân tích của cá nhân tôi. Để mọi người có thể tham khảo cũng như đóng góp ý kiến cho tôi

## The Analysis (Phân tích) 📈

1. Tìm ra tổng số vụ va chạm theo mức độ nghiêm trọng
```sql
SELECT
  Accident_Severity Severity,
  FORMAT(COUNT(Accident_Index),'N0') Number_Accident
FROM Accident_data
GROUP BY Accident_Severity
ORDER BY COUNT(Accident_Index) DESC;
```
![Hình 1](Pictures/1.png)

2. Tính số lượng vụ va chạm tính theo lượng phương tiện giao thông
```sql
SELECT
  Vehicle_Type,
  FORMAT(COUNT(Accident_Index),'N0') Number_Accident
FROM Accident_data
GROUP BY Vehicle_Type
ORDER BY COUNT(Accident_Index) DESC;
```
![Hình 2](Pictures/2.png)

3. Tính phần trăm thay đổi trong số vụ va chạm so với tháng liên trước đó
```sql
WITH Table1 as
  (SELECT 
    YEAR([accident date]) Year,
    MONTH([accident date]) Month,
    FORMAT([accident date], 'MMM') Month_text,
    COUNT(accident_index) Cur_Number_accident,
    LAG(COUNT(accident_index)) OVER (PARTITION BY YEAR([accident date]) ORDER BY MONTH([accident date]) ASC) Pre_Number_accident
  FROM accident_data
  GROUP BY Year([accident date]), Month([accident date]), FORMAT([accident date], 'MMM')
  )
------
SELECT 
  Year, Month_text as Month,
  Cur_Number_accident Number_Accident,
  FORMAT(ISNULL((Cur_Number_accident - Pre_Number_accident)/ CAST(Pre_Number_accident as DECIMAL(10,2)),0),'P2') '% Change'
FROM Table1;
```
![Hình 2](Pictures/3.png)

4. Xác định TOP 3 loại phương tiên giao thông có số lượng va chạm nhiều nhất theo từng khung thời gian trong ngày
```sql
WITH Table1 as
  (SELECT 
    MONTH([Accident Date]) Month_Num,
    DATENAME(MONTH, [Accident Date]) Month_text,
    Time_of_day,
    FORMAT(COUNT(Accident_Index), 'N0') Number_Accident,
    RANK() OVER (PARTITION BY Time_of_day ORDER BY COUNT(Accident_Index) DESC) Rank
  FROM Accident_data
  GROUP BY MONTH([Accident Date]), Time_of_day, DATENAME(MONTH, [Accident Date]))
------
SELECT
  Month_text,
  Time_of_day,
  Number_Accident
FROM Table1
WHERE Rank <= 3
```
![Hình 2](Pictures/4.png)

5. Tính lũy kế cộng dồn số vụ va chạm theo thời gian
```sql
WITH Table1 as
  (SELECT 
    Year([accident date]) Year,
    Month([accident date]) Month,
    FORMAT([accident date], 'MMM') Month_text,
    COUNT(accident_index) Number_accident
  FROM accident_data  
  GROUP BY Year([accident date]), MONTH([accident date]), FORMAT([accident date], 'MMM'))
------
SELECT 
  cur.Year, 
  cur.Month,
  cur.Number_accident Current_year,
  pre.Number_accident Previous_year,
  cur.Number_accident - pre.Number_accident Difference,
  FORMAT((cur.Number_accident - pre.Number_accident)/CAST(pre.Number_accident as DECIMAL(10,2)),'P2') '% Difference'
FROM Table1 as cur
JOIN Table1 as pre ON cur.year = pre.Year + 1  AND cur.Month = pre.Month
ORDER BY Year ASC, Month ASC
```
![Hình 2](Pictures/5.png)

6. Xác định sự tăng hoặc giảm số lượng vụ va chạm của năm hiện tại (2022) so với năm trước đó (2021)
```sql
WITH table1 as
  (SELECT 
    YEAR([Accident Date]) Year,
    FORMAT([accident date],'MMM') Month_text,
    MONTH([accident date]) Month,
    SUM(Number_of_Casualties) Total
  FROM Accident_data
  GROUP BY YEAR([accident date]), FORMAT([accident date], 'MMM'), MONTH([accident date]))
------
SELECT 
  Year, Month_text,
  FORMAT(Total,'C0') Total_Revenue,
  FORMAT(SUM(total) OVER (PARTITION BY YEAR ORDER BY year ASC, month ASC),'C0') Accumulative_Total_Revenue
FROM table1 
```
![Hình 2](Pictures/6.png)

## Conclusion (Kết luận) 📝


