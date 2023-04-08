
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


