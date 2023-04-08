
CREATE OR ALTER PROCEDURE [dbo].[proc_data_by_dates]
AS
BEGIN
    TRUNCATE TABLE data_by_dates;
    
    DECLARE @assno INT, @userId INT;
    DECLARE daily_cursor CURSOR FOR SELECT ssno, userId FROM firm_list;
    
    -- Declare a table variable of the same structure as the temp_day table
    DECLARE @temp_day TABLE (
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
    
    OPEN daily_cursor;
    FETCH NEXT FROM daily_cursor INTO @assno, @userId;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Insert the data into the table variable
        INSERT INTO @temp_day EXEC daily_by_ssno @assno;
       
        -- Insert the data from the table variable into the data_by_dates table
        INSERT INTO data_by_dates (id, facility, district, date, active, capacitive, 
            inductive, ssno, userId, active_cons, inductive_cons, capacitive_cons) 
        SELECT id, facility, district, date, active, capacitive, 
            inductive, ssno, @userId, active_cons, inductive_cons, capacitive_cons
        FROM @temp_day;
        
        DELETE FROM @temp_day;
        FETCH NEXT FROM daily_cursor INTO @assno, @userId;
    END
    CLOSE daily_cursor;
    DEALLOCATE daily_cursor;
END
GO


