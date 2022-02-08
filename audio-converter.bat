:: Made by Philip Tønnessen
:: 17.04.2021 - 03.02.2022

@echo off

:: Sets active code page to unicode,
:: allowing the script to deal with special 
:: characters in filenames.
chcp 65001

SET ffmpeg=bin\ffmpeg-n4.4-latest-win64-lgpl-4.4\bin\ffmpeg.exe
SET albumart=bin\no_cover\no_album_art__no_cover.jpg
SET metaflac=bin\flac-1.3.2-win\win64\metaflac.exe

IF NOT EXIST original mkdir original
IF NOT EXIST exports mkdir exports

echo.
SET /P filetype="Enter the filetype of files in 'input' folder (ex: "mp3", "flac" etc.): "
echo.
SET /P filetype_out="Enter the desired output filetype (ex: "mp3", "flac" etc.): "

:output_folder_q
echo. 
SET /P output_q="Do you want to save the file(s) in a separate folder? (y/n): "
IF /I "%output_q%" == "y" (
goto folder_sel
) ELSE IF /I "%output_q%" == "n" (
SET output_folder=exports
goto extract_album
) ELSE (
echo. 
echo Error: Invalid input
goto output_folder_q)

:folder_sel
echo. 
SET /P folder="Specify folder name (no quotes): "
SET output_folder=exports\%folder%
IF NOT EXIST "exports\%folder%" mkdir "exports\%folder%"

:extract_album
IF NOT EXIST tmp mkdir tmp
FOR /F "tokens=*" %%G IN ('dir /b input\*.%filetype%') DO %ffmpeg% -i "input\%%G" -an -vcodec copy "tmp\%%~nG.jpg" & move "input\%%G" original & SET file=%%~nG& goto album_file_checker

:album_file_checker
IF NOT EXIST "tmp\%file%.jpg" goto no_albumart
goto existing_albumart

:existing_albumart
SET albumart_syntax=
goto encoder_options

:no_albumart
SET albumart_syntax=-i "%albumart%" -map 0:0 -map 1:0 -id3v2_version 3 -metadata:s:v title="Album cover" -metadata:s:v comment="Cover (front)"
goto encoder_options

:encoder_options
IF /I "%filetype_out%" == "mp3" (
SET codec_options=-b:a 320k
) ELSE IF /I "%filetype_out%" == "m4a" (
SET codec_options=-vn -aq 6
) ELSE IF /I "%filetype_out%" == "ogg" (
SET codec_options=-vn -aq 6
) ELSE (
SET codec_options=)

:convert
%ffmpeg% -i "original\%file%.%filetype%" %albumart_syntax% %codec_options% "tmp\%file%.%filetype_out%" && move "tmp\%file%.%filetype_out%" "%output_folder%" && goto navigate

:navigate
IF /I "%filetype_out%" == "flac" (
goto add_album_image_flac
) ELSE (
goto checker)

:add_album_image_flac
%metaflac% --import-picture-from %albumart% "%output_folder%\%file%.%filetype_out%" && DEL /F "tmp\%file%.jpg" && goto checker

:checker
IF NOT EXIST input\*.%filetype% goto done
goto extract_album

:done
rmdir /s /q "tmp"
start "" "%cd%\%output_folder%"
exit
