# Data Analysis and Reporting with SQL SERVER
## Designing and Implementing a SQL Server Database for Electrical Energy Analysis: A Case Study
In this project, we present a case study of designing and implementing a SQL Server database for electrical energy analysis. Additionally, we include `stored procedures` to process the data by date, hour, and month. Finally, we present a `trigger` script to update all reports when a new entry is added to the consumptions table. In this repository, we provide a `Dockerfile` to set up an instance of SQL Server 2019 with some configuration options and a user with administrative privileges. The repository also includes an overview of the scripts and stored procedures included in this project. 

---------
### Install SQL Server on Linux using Docker

This Dockerfile sets up an instance of `SQL Server 2019` with some configuration options and a user with administrative privileges. It also creates a database directory, sets environment variables for SQL Server, enables remote connections, adds a volume for data persistence, and exposes port 1433.

To build the Docker image, `run docker build -t sqlserver .`. To run the container, use `docker run -d -p 1433:1433 -v my_sql_data:/var/opt/mssql/data sqlserver`.
```
FROM mcr.microsoft.com/mssql/server:2019-latest

# Set environment variables for SQL Server instance
ENV SA_PASSWORD=cGFzc3dvcmQ=
ENV ACCEPT_EULA=Y

# Create a database directory
RUN mkdir -p /var/opt/mssql/data

# Grant permissions to the database directory
RUN chmod -R g=u /var/opt/mssql/data

# Create a new user with admin privileges
ENV MSSQL_PID=Developer
ENV MSSQL_AGENT_ENABLED=true
ENV MSSQL_COLLATION=SQL_Latin1_General_CP1_CI_AS
ENV MSSQL_TCP_PORT=1433
ENV MSSQL_LCID=1033
ENV MSSQL_MEMORY_LIMIT_MB=2048
ENV MSSQL_USERNAME=worker
ENV MSSQL_PASSWORD=cGFzc3dvcmQ=
ENV MSSQL_USER_HOME=/home/worker

USER root
RUN useradd -u 10101 -m -s /bin/bash -p $(openssl passwd -1 ${MSSQL_PASSWORD}) ${MSSQL_USERNAME}
RUN usermod -aG sudo ${MSSQL_USERNAME}

# Enable remote connections
RUN echo 'export MSSQL_PID=Developer' >> ~/.bashrc
RUN echo 'export MSSQL_TCP_PORT=1433' >> ~/.bashrc
RUN echo 'export MSSQL_COLLATION=SQL_Latin1_General_CP1_CI_AS' >> ~/.bashrc
RUN echo 'export MSSQL_LCID=1033' >> ~/.bashrc
RUN echo 'export MSSQL_USER_HOME=/home/newuser' >> ~/.bashrc
RUN echo 'export ACCEPT_EULA=Y' >> ~/.bashrc
RUN echo 'export SA_PASSWORD=ODcxNzYxNUJhcy4=' >> ~/.bashrc

# Add a volume to persist data
VOLUME /var/opt/mssql/data

# Expose the SQL Server port
EXPOSE 1433

# Start SQL Server
CMD /opt/mssql/bin/sqlservr
```

Note that the `SA_PASSWORD` environment variable is set to password and the password has been encoded with `base64`. To change the password, you can replace password with a new password and encode it with base64 using `echo -n "password" | base64`.

---------------------------------------------------------------------------------------------------------------
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

### Scripts
The scripts generate reports in various time intervals, such as hourly, daily, weekly, and monthly. They also include procedures to process the data by date, hour, and month. Finally, there is a trigger script to update all reports when a new entry is added to the consumptions table.

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
  ----------------------------------------------------------------------------------------------------------------------------------------
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

------------------------------------------------------------------------------------------------------------------------------------------

```

CREATE OR ALTER       PROCEDURE [dbo].[proc_data_by_months]
AS
BEGIN
    TRUNCATE TABLE data_by_months;
    
    DECLARE @assno INT, @userId INT;
    DECLARE monthly_cursor CURSOR FOR SELECT ssno, userId FROM firm_list;
    
    -- Declare a table variable of the same structure as the temp_month table
    DECLARE @temp_month TABLE (
		id INT IDENTITY(1,1),
        facility VARCHAR(255),
        district VARCHAR(255),
        date DATE,
        active INT,
        capacitive INT,
        inductive INT,
        ssno INT,
        userId INT,
        active_cons INT,
        inductive_cons INT,
        capacitive_cons INT,
        inductive_ratio DECIMAL(10,2),
        capacitive_ratio DECIMAL(10,2),
        penalized INT
    );
    
    OPEN monthly_cursor;
    FETCH NEXT FROM monthly_cursor INTO @assno, @userId;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Insert the data into the table variable
        INSERT INTO @temp_month EXEC monthly_current_by_ssno @assno;

        -- Insert the data from the table variable into the data_by_months table
        INSERT INTO data_by_months (id, facility, district, date, active, capacitive, 
            inductive, ssno, userId, active_cons, inductive_cons, capacitive_cons, 
            inductive_ratio, capacitive_ratio, penalized) 
        SELECT id, facility, district, date, active, capacitive, 
            inductive, ssno, @userId, active_cons, inductive_cons, capacitive_cons, 
            inductive_ratio, capacitive_ratio, penalized
        FROM @temp_month;
        
        DELETE FROM @temp_month;
        FETCH NEXT FROM monthly_cursor INTO @assno, @userId;
    END
    CLOSE monthly_cursor;
    DEALLOCATE monthly_cursor;
END
GO
```

This stored procedure has the following main functionality:

- It truncates the data_by_months table to remove any existing data.
- It declares a cursor named monthly_cursor to select ssno and userId from firm_list.
- It declares a table variable named `@temp_month` that has the same structure as the `#temp_month` temporary table in the previous stored procedure.
- It opens the `monthly_cursor` and fetches the first row of data into `@assno` and `@userId`.
- It executes the `monthly_current_by_ssno` stored procedure to retrieve the monthly data for the selected ssno.
- It inserts the retrieved data into the `@temp_month` table variable.
- It inserts the data from the `@temp_month` table variable into the `data_by_months` table, with `userId` set to the value of the variable `@userId`.
- It fetches the next row of data from the `monthly_cursor` and repeats steps until there is no more data to fetch.
-------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------

### Trigger

```
CREATE OR ALTER TRIGGER [dbo].[update_all_trigger]
ON [dbo].[consumptions]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    EXEC sp_msforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT all";
    EXEC proc_data_by_months;
    EXEC proc_data_by_weeks;
    EXEC proc_data_by_dates;
    EXEC proc_data_by_hours;
    EXEC sp_msforeachtable "ALTER TABLE ? CHECK CONSTRAINT all";
END
GO

ALTER TABLE [dbo].[consumptions] ENABLE TRIGGER [update_all_trigger]
GO
```

This T-SQL trigger named `"update_all_trigger"` is created or altered to run on the `"consumptions"` table in the "dbo" schema. The trigger fires after an insert or update operation is performed on the table.

The trigger contains a series of T-SQL statements that perform various data processing tasks, including:

- Disabling all constraints on all tables in the database using the `sp_msforeachtable system stored procedure`.
- Calling several `user-defined procedures` named `"proc_data_by_months"`, `"proc_data_by_weeks"`, `"proc_data_by_dates"`, and `"proc_data_by_hours"` that process data in the `"consumptions"` table based on different time intervals.
- Enabling all constraints on all tables in the database using the `sp_msforeachtable` system stored procedure.

The `SET NOCOUNT ON` statement is used to prevent the sending of the count of the number of rows affected by the trigger.

The `ALTER TABLE` statement at the end of the trigger enables the trigger to fire for the `"consumptions"` table.

Overall, this trigger performs data processing tasks on the `"consumptions"` table in the `"dbo"` schema, with the aim of updating data based on different time intervals. It disables all constraints before performing the data processing and then re-enables them afterward.

### SQL Server Indexes
Indexes in SQL Server are database structures that help improve the performance of database queries by allowing the database engine to quickly locate data within a table. They can be created on one or more columns of a table and are organized in a B-tree structure that supports efficient data retrieval operations. Indexes can speed up queries that use the indexed columns in the WHERE, JOIN, and ORDER BY clauses, but can also slow down data modification operations such as INSERT, UPDATE, and DELETE.

Run query before Index:

When running the SELECT query, the following message was received: `"Table 'consumptions'. Scan count 1, logical reads 917, physical reads 0 etc."`. This indicates that the query was performing a full table scan and accessing a large number of pages in the buffer cache.

![](https://github.com/skrbyrm/Designing-and-Implementing-a-SQL-Server-Database-for-Electrical-Energy-Analysis-A-Case-Study/blob/main/ss1.png)

Click! `Display Estimated Execution Plan` "Display Estimated Execution Plan" is a feature in SQL Server Management Studio (SSMS) that allows you to view an estimated execution plan for a Transact-SQL (T-SQL) query.

An execution plan shows how SQL Server will execute a query, including the order in which it will read tables, join data, apply filters, and retrieve data. The estimated execution plan is based on SQL Server's query optimizer and provides insight into how the optimizer will execute the query.
Analyzing the estimated execution plan can help you identify performance issues in your queries, such as missing indexes, inefficient joins, or excessive data scans. By understanding how SQL Server is executing your queries, you can make informed decisions about how to optimize them for better performance.

Here is `Display Estimated Execution Plan` result:
```
/*
Missing Index Details from SQLQuery1.sql - <HOST>.cons (sa (55))
The Query Processor estimates that implementing the following index could improve the query cost by 97.81%.
*/


USE [cons]
GO
CREATE NONCLUSTERED INDEX [ssno_Index, sysname]
ON [dbo].[consumptions] ([ssno])
INCLUDE ([date],[active],[inductive],[capacitive],[hno],[facility_id],
	[createdAt],[updatedAt])
GO
```
After creating and rebuilding the `NONCLUSTERED INDEX`, the `SELECT` query was rerun and the following message was received: `"Table 'consumptions'. Scan count 1, logical reads 27, physical reads 0 etc. "`. This indicates that the query was able to use the index to quickly locate the relevant rows and access a much smaller number of pages in the buffer cache.

![](https://github.com/skrbyrm/Designing-and-Implementing-a-SQL-Server-Database-for-Electrical-Energy-Analysis-A-Case-Study/blob/main/ss3.png)

By creating and adding the nonclustered index on the ssno column of the consumptions table, the performance of the `SELECT` query was significantly improved. This demonstrates the importance of proper indexing in optimizing database performance.


