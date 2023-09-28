:: #### Server Starter v3.1.4 ###
:: #### (c) Novtalath 2023	  ###
@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: ---------------------  CONFIG SECTION START ---------------------------

:: Modpack name
set "MODPACK=OPSkies2"

:: ---- Java version ----
:: Please comment lines with dual "::" depending on what Java version is to be used. If all commented
:: Starter will use default Java installed.

:: ------------------------------------------------------------------------
:: ##############    JAVA 17   ###############
:: Edit the lines below for Java 17.0 to be used.
:: Default folder location is used. Please change the location as required.
:: ------------------------------------------------------------------------
set "JAVA_VERSION=17.0"
set JAVA_PATH="C:\Program Files\Java\jdk-17\bin"
:: ------------------------------------------------------------------------

:: ##############    JAVA 8    ###############
:: ------------------------------------------------------------------------
:: Edit the lines below for Java 1.8 to be used.
:: Default folder location is used. Please change the location as required.
:: ------------------------------------------------------------------------
::set "JAVA_VERSION=1.8"
::set JAVA_PATH="C:\Program Files\Java\jre1.8.0_351\bin"
:: ------------------------------------------------------------------------

:: ------------------------------------------------------------------------
:: Minecraft Forge version to be used with the pack.
:: If not installed - Starter will download the required version and install it.
set "FORGE_VERSION=1.18.2-40.2.10"
:: ------------------------------------------------------------------------

:: ------------------------------------------------------------------------
:: Settings for Min and Max RAM to be used with server.
::These will be added to USER_JVM_ARGS.txt file AFTER it is created by server installer. 
set "MIN_RAM=4G"
set "MAX_RAM=8G"
:: ------------------------------------------------------------------------



:: ------------------------  CONFIG SECTION END ---------------------------

:: ######################################################################################################################################

:: ################################### !!!! DO NOT EDIT ANYTHING BELOW UNLESS YOU KNOW WHAT YOU ARE DOING !!!! ##########################

:: ######################################################################################################################################



:: Check Java version

	set JAVA_EXECUTABLE=%JAVA_PATH%\java
	call :check_java JAVA_VER

:: echo Checking if !JAVA_VER! is equal or greater than !JAVA_VERSION!

if !JAVA_VER! GEQ !JAVA_VERSION! (
  echo Installed Java version of !JAVA_VER! is at least %JAVA_VERSION%.
  timeout /t 1 >nul
) else (
  goto java_error
)

:: Check if Forge is installed
if not exist libraries\net\minecraftforge\forge\%FORGE_VERSION%\win_args.txt (
	if not exist forge-%FORGE_VERSION%-installer.jar (
		echo Forge %FORGE_VERSION% is not installed. Downloading...
		powershell -Command "(New-Object Net.WebClient).DownloadFile('https://maven.minecraftforge.net/net/minecraftforge/forge/%FORGE_VERSION%/forge-%FORGE_VERSION%-installer.jar', 'forge-%FORGE_VERSION%-installer.jar')"
		echo Forge %FORGE_VERSION% downloaded.
		echo Installing Forge %FORGE_VERSION%...
		%JAVA_EXECUTABLE% -jar forge-%FORGE_VERSION%-installer.jar --installServer
		echo Forge %FORGE_VERSION% has been installed.
		call :eula
	) else (
		echo Installing Forge %FORGE_VERSION%...
		%JAVA_EXECUTABLE% -jar forge-%FORGE_VERSION%-installer.jar --installServer
		echo Forge %FORGE_VERSION% has been installed.
		call :eula
	)
)

:: Check if user_jvm_args.txt exists, and add Xms and Xmx if they don't exist.

set "jvm_args_file=user_jvm_args.txt"
set "tempfile=temp.txt"

if not exist "%jvm_args_file%" (
  echo -Xms%MIN_RAM% > "%jvm_args_file%"
  echo -Xmx%MAX_RAM% >> "%jvm_args_file%"
  echo Arguments for min and max RAM added to %jvm_args_file%.
  timeout /t 1 >nul
) else (
	(for /F "tokens=1* delims=:" %%i in ('findstr /N "^" "%jvm_args_file%"') do (
		set "line=%%j"
		if %%i==1 (
			echo -Xms%MIN_RAM%
		) else if %%i==2 (
			echo -Xmx%MAX_RAM%
		) else (
			echo !line!
			)
		)
	) > "%tempfile%"

move /y "%tempfile%" "%jvm_args_file%" > nul
  echo Arguments for min and max RAM have been updated in %jvm_args_file%.
  timeout /t 2 >nul
)

:start_server
title %MODPACK% Server
color 0A
prompt [server]:
if  !JAVA_VER!=="1.8" (
	goto :start_8
	) else (
	goto :start_17
	)

:start_8
cls
echo ############################################################
echo.
echo Starting server... Java 1.8
echo.
echo ############################################################
timeout /t 1 >nul
%JAVA_EXECUTABLE% -d64 -server -classpath .\user_jvm_args.txt -jar .\libraries\net\minecraftforge\forge\%forgever%\%_JAR_FILE% %* nogui
goto :choice
::cls

:start_17
cls
echo ############################################################
echo.
echo Starting server ... Java 17+
echo.
echo ############################################################
timeout /t 1 >nul
%JAVA_EXECUTABLE% @%jvm_args_file% @libraries\net\minecraftforge\forge\%FORGE_VERSION%\win_args.txt nogui
::cls

:choice
setlocal enabledelayedexpansion
echo ############################################################
echo.
choice /C YN /M "Do you want to restart server? (default - Y): " /T 5 /D Y
echo.
echo ############################################################
if "!errorlevel!"=="1" goto :restart
if "!errorlevel!"=="2" goto :stop
endlocal
goto :choice

:restart
echo.
echo.
echo ############################################################
echo.
echo Server will now restart.
echo.
echo ############################################################
timeout /T 1 >nul
if  %JAVA_VER% == "1.8" (
	goto :start_8
	) else (
	goto :start_17
	)

:stop
cls
echo.
echo.
echo ############################################################
echo.
echo Closing server.
echo.
echo ############################################################
timeout /T 2 >nul
goto eof

:java_error
cls
color 04
echo  *******************************************************************
echo  ************************ FATAL ERROR ******************************
echo  *******************************************************************
echo  ******************  Java %java_version% is not installed. *******************
echo  ****** Install correct java environment and/or set JAVA_HOME ******
echo  *******************************************************************
echo  *******************************************************************
timeout /T 5 >nul
goto eof

:check_java
for /f tokens^=2-5^ delims^=.-_^" %%a in ('"%JAVA_EXECUTABLE%" -fullversion 2^>^&1') do (
    set "%1=%%a.%%b"
)

goto eof

:eula

	if exist ".\eula.txt" (
		goto e_yes_edit
		) else (
		goto e_new
		)

goto :eof
	
:e_yes_edit
	echo.
	echo File eula.txt already exist. Do you still agree with EULA? (https://account.mojang.com/documents/minecraft_eula)
	echo.
	set choice=
	set /p choice = Choose (y) or (n) (default: y) : 
	
		if not '%choice%'=='' (
			set choice=%choice:~0,1%
			) else (
			set choice=y
		)
	
		if '%choice%'=='n' goto e_no
		
		echo Agreed with EULA. Saving information.
		
		ren "eula.txt" "eula.tmp"
		
		(for /F "tokens=1* delims=:" %%a in ('findstr /N "^" eula.tmp') do (
				set "line=%%b"
				if defined line set "line=!line:false=true!"
				echo(!line!)
			) > eula.txt
			del "eula.tmp"
			goto eof
		)
	
:e_new
	
	set varEULA=
	set /p varEULA="Type 'true' to agree to EULA (https://account.mojang.com/documents/minecraft_eula) : "
		if /i '%varEULA%'=='true' (
			echo.
			echo Agreed with EULA. Saving information.
			goto e_create
			) else (
			goto e_no
		)
	goto eof

:e_no
echo EULA declined. Making adequate changes to eula.txt
echo You will have to edit file eula.txt and change the option 'eula=true' if you want to run your server.
echo.
del eula.txt
echo #By changing the setting below to TRUE you are indicating your agreement to our EULA (https://account.mojang.com/documents/minecraft_eula). > eula.txt
echo #Mon Jul 11 20:24:54 BST 2022 >> eula.txt
echo eula=false >> eula.txt
goto eof

:e_create
set curtime=
set yy=%date:~-4%
FOR /f "tokens=1 delims= " %%a in ('tzutil/g') do set tzone=%%a
for /f "tokens=*" %%x in ('powershell -NoLogo -NonInteractive -OutputFormat Text -Command "[DateTime]::Now.ToString(\"ddd MMM dd HH:mm:ss\")"') do set curtime=%%x
echo #By changing the setting below to TRUE you are indicating your agreement to our EULA (https://account.mojang.com/documents/minecraft_eula). > eula.txt
echo #%curtime% %tzone% %yy% >> eula.txt
echo eula=true>> eula.txt

:eof
cls
color