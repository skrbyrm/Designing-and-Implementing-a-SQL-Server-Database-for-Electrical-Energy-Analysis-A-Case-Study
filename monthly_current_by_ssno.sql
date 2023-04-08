
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


