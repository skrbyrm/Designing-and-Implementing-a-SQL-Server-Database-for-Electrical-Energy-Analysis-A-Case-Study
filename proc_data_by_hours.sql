
CREATE OR ALTER PROCEDURE [dbo].[proc_data_by_hours]
AS
BEGIN
    TRUNCATE TABLE data_by_hours;
    
    DECLARE @assno INT, @userId INT;
    DECLARE hourly_cursor CURSOR FOR SELECT ssno, userId FROM firm_list;
    
    -- Declare a table variable of the same structure as the temp_hour table
    DECLARE @temp_hour TABLE (
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
    
    OPEN hourly_cursor;
    FETCH NEXT FROM hourly_cursor INTO @assno, @userId;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Insert the data into the table variable
        INSERT INTO @temp_hour EXEC hourly_by_ssno @assno;
        
        -- Insert the data from the table variable into the data_by_hours table
        INSERT INTO data_by_hours (id, facility, district, date, active, capacitive, 
            inductive, ssno, userId, active_cons, inductive_cons, capacitive_cons) 
        SELECT id, facility, district, date, active, capacitive, 
            inductive, ssno, @userId, active_cons, inductive_cons, capacitive_cons
        FROM @temp_hour;
        
        DELETE FROM @temp_hour;
        FETCH NEXT FROM hourly_cursor INTO @assno, @userId;
    END
    CLOSE hourly_cursor;
    DEALLOCATE hourly_cursor;
END
GO


