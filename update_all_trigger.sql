
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


