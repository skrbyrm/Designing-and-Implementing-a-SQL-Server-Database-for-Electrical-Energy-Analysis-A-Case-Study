# Data Analysis and Reporting with SQL SERVER
## Designing and Implementing a SQL Server Database for Electrical Energy Analysis: A Case Study

This project consists of several SQL scripts for analyzing and reporting data from a consumptions table with the following schema:
Base Table
```
CREATE TABLE [dbo].[consumptions](
	[id] [int] NOT NULL,
	[date] [datetime] NULL,
	[active] [float] NULL,
	[inductive] [float] NULL,
	[capacitive] [float] NULL,
	[hno] [bigint] NULL,
	[ssno] [bigint] NULL,
	[facility_id] [int] NULL,
	[createdAt] [datetime] NULL,
	[updatedAt] [datetime] NULL,
 CONSTRAINT [PK_consumptions] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)) ON [PRIMARY]

```

The scripts generate reports in various time intervals, such as hourly, daily, weekly, and monthly. They also include procedures to process the data by date, hour, and month. Finally, there is a trigger script to update all reports when a new entry is added to the consumptions table.

### Scripts

  - `daily_by_ssno.sql`: Generates a report of daily consumption by ssno.
  - `hourly_by_ssno.sql`: Generates a report of hourly consumption by ssno.
  - `monthly_current_by_ssno.sql`: Generates a report of monthly consumption by ssno.
  - `proc_data_by_dates.sql`: A stored procedure that processes the data by date.
  - `proc_data_by_hours.sql`: A stored procedure that processes the data by hour.
  - `proc_data_by_months.sql`: A stored procedure that processes the data by month.
  - `proc_data_by_weeks.sql`: A stored procedure that processes the data by week.
  - `update_all_trigger.sql`: A trigger script that updates all reports when a new entry is added to the consumptions table.
  - `weekly_by_ssno.sql`: Generates a report of weekly consumption by ssno.
  
  ### Stored Procedures
  
  ```
CREATE OR ALTER   PROCEDURE [dbo].[monthly_current_by_ssno]
    @meterid int
AS
BEGIN
    IF OBJECT_ID('tempdb..#temp_month') IS NOT NULL
        DROP TABLE #temp_month;
    
    SELECT *, 
        CASE 
            WHEN tab.inductive_ratio >= 20 or tab.capacitive_ratio >= 15 THEN 1 
            ELSE 0 
        END AS penalized
    INTO #temp_month
    FROM (
        SELECT 
            firm_list.facility, 
            firm_list.district, 
            q.date, 
            q.active, 
            q.capacitive, 
            q.inductive, 
            q.ssno, 
            q.userId,
            ROUND(q.active - COALESCE(LAG(q.active) OVER (PARTITION BY q.ssno ORDER BY q.date ASC), 0), 2) AS active_cons,
            ROUND(q.inductive - COALESCE(LAG(q.inductive) OVER (PARTITION BY q.ssno ORDER BY q.date ASC), 0), 2) AS inductive_cons,
            ROUND(q.capacitive - COALESCE(LAG(q.capacitive) OVER (PARTITION BY q.ssno ORDER BY q.date ASC), 0), 2) AS capacitive_cons,
            CASE 
                WHEN q.active - COALESCE(LAG(q.active) OVER (PARTITION BY q.ssno ORDER BY q.date ASC), 0) = 0 THEN 0 
                ELSE ROUND(((q.inductive - COALESCE(LAG(q.inductive) OVER (PARTITION BY q.ssno ORDER BY q.date ASC), 0)) / (q.active - COALESCE(LAG(q.active) OVER (PARTITION BY q.ssno ORDER BY q.date ASC), 0))) * 100, 4) 
            END AS inductive_ratio,
            CASE 
                WHEN q.active - COALESCE(LAG(q.active) OVER (PARTITION BY q.ssno ORDER BY q.date ASC), 0) = 0 THEN 0 
                ELSE ROUND(((q.capacitive - COALESCE(LAG(q.capacitive) OVER (PARTITION BY q.ssno ORDER BY q.date ASC), 0)) / (q.active - COALESCE(LAG(q.active) OVER (PARTITION BY q.ssno ORDER BY q.date ASC), 0))) * 100, 4) 
            END AS capacitive_ratio
        FROM (
            SELECT 
                firm_list.userId AS userId,
                firm_list.ssno AS ssno,
                MAX(c.date) AS date,
                MAX(c.active) AS active,
                MAX(c.inductive) AS inductive,
                MAX(c.capacitive) AS capacitive
            FROM            
                consumptions c
            INNER JOIN
                firm_list ON c.ssno = firm_list.ssno
            GROUP BY 
                firm_list.ssno, 
                firm_list.userId, 
                MONTH(c.date)
        ) AS q
        INNER JOIN
            firm_list ON q.ssno = firm_list.ssno
        WHERE 
            firm_list.ssno = @meterid
        ORDER BY 
            q.date DESC
        OFFSET 0 ROWS FETCH NEXT 1 ROW ONLY
    ) AS tab;

    SELECT *
    FROM #temp_month
    ORDER BY 
        date DESC;
END
GO
```

This is a SQL Server stored procedure that takes an integer parameter @meterid and returns a result set with columns related to electricity consumption for a specific meter. Here are some comments on the code:

- The stored procedure starts by checking if a temporary table named `#temp_month` exists and drops it if it does. This is to ensure that the table is clean and not already present.
- The stored procedure then selects data from the consumptions table and the `firm_list` table, joining them on the `ssno` column. It groups the data by `ssno`, `userId`, and `MONTH(date)` and calculates the maximum values of `active`, `inductive`, and `capacitive` columns for each group. This means that for each month, the procedure gets the maximum consumption values for a specific meter and user.
- The `LAG()` function is then used to calculate the difference between the current `consumptio`n and the previous month's consumption for each type of consumption `(active, inductive, capacitive)`. These differences are rounded to two decimal places and stored in columns with names like `active_cons`.
- The `inductive_ratio` and `capacitive_ratio` columns are then calculated as the ratio between the difference in `inductive` or `capacitive` consumption and the difference in active consumption, multiplied by 100 and rounded to four decimal places. These ratios are only calculated if the difference in active consumption is not zero.
- The penalized column is calculated as a boolean value (0 or 1) based on the values of `inductive_ratio` and `capacitive_ratio`. If either ratio is greater than or equal to a threshold value, the column is set to 1. Otherwise, it is set to 0.
- All of this data is then inserted into the temporary table `#temp_month`.
- Finally, the stored procedure selects all columns from the temporary table and orders them by the date column in descending order (i.e., most recent first). This result set is returned to the caller.

Overall, this stored procedure calculating and summarizing electricity consumption data for a specific meter, the purpose of penalizing customers with excessive inductive or capacitive loads.

