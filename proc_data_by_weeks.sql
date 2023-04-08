
CREATE OR ALTER   PROCEDURE [dbo].[proc_data_by_weeks]
AS
BEGIN
    TRUNCATE TABLE data_by_weeks;
    
    DECLARE @assno INT, @userId INT;
    DECLARE weekly_cursor CURSOR FOR SELECT ssno, userId FROM firm_list;
    
    -- Declare a table variable of the same structure as the temp_week table, with an incremental ID column
    DECLARE @temp_week TABLE (
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
    
    OPEN weekly_cursor;
    FETCH NEXT FROM weekly_cursor INTO @assno, @userId;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Insert the data into the table variable
        INSERT INTO @temp_week EXEC weekly_by_ssno @assno;
        
        -- Insert the data from the table variable into the data_by_weeks table, using the temp_id as the primary key
        INSERT INTO data_by_weeks (id, facility, district, date, active, capacitive, 
            inductive, ssno, userId, active_cons, inductive_cons, capacitive_cons, 
            inductive_ratio, capacitive_ratio, penalized) 
        SELECT id, facility, district, date, active, capacitive, 
            inductive, ssno, @userId, active_cons, inductive_cons, capacitive_cons, 
            inductive_ratio, capacitive_ratio, penalized
        FROM @temp_week;
        
        DELETE FROM @temp_week;
        FETCH NEXT FROM weekly_cursor INTO @assno, @userId;
    END
    CLOSE weekly_cursor;
    DEALLOCATE weekly_cursor;
END
GO


