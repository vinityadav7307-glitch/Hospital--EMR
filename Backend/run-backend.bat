@echo off
setlocal
if "%HEALPOINT_DB_NAME%"=="" set HEALPOINT_DB_NAME=hospital_emr
if "%HEALPOINT_DB_HOST%"=="" set HEALPOINT_DB_HOST=localhost
if "%HEALPOINT_DB_PORT%"=="" set HEALPOINT_DB_PORT=3306
if "%HEALPOINT_DB_USER%"=="" set HEALPOINT_DB_USER=root
if "%HEALPOINT_DB_PASSWORD%"=="" (echo Set HEALPOINT_DB_PASSWORD before running.& exit /b 1)
call mvnw spring-boot:run
if errorlevel 1 mvn spring-boot:run
