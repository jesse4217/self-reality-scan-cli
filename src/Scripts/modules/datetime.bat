@echo off
:: datetime.bat - Date and time utility functions
:: Provides formatted date/time variables for logging and file naming

:: Get current date components
for /f "tokens=1-4 delims=/ " %%i in ("%date%") do (
    set dow=%%i
    set month=%%j
    set day=%%k
    set year=%%l
)

:: Get current time components
FOR /F "TOKENS=1 DELIMS=:" %%A IN ('TIME/T') DO SET HH=%%A
FOR /F "TOKENS=2 DELIMS=:" %%A IN ('TIME/T') DO SET MM=%%A

:: Create formatted date string
set FormattedDate=%year%-%dow%-%month%-%day%-%HH%-%MM%

:: Alternative formats for different uses
set DateOnly=%year%-%month%-%day%
set TimeOnly=%HH%-%MM%
set Timestamp=%year%%month%%day%_%HH%%MM%

:: Export variables for use by calling script
echo Date/Time Variables Set:
echo   FormattedDate: %FormattedDate%
echo   DateOnly: %DateOnly%
echo   TimeOnly: %TimeOnly%
echo   Timestamp: %Timestamp%

:: Return success
exit /b 0