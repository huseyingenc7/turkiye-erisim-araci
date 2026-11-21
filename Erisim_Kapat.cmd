@ECHO OFF
REM Acik kalan GoodbyeDPI'i ve DNS koprusunu kapatir, DNS ayarlarini eski haline dondurur. Yonetici izni ister.
net session >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  EXIT /B
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0erisim_ac.ps1" -Kapat
