echo off
mode con cols=50 lines=5
title=building......
taskkill /f /im pxesrv.exe
taskkill /f /im hfs.exe
cd /d %~dp0

if not exist %~dp0boot mkdir %~dp0boot
for /f %%i in ('dir /b %~dp0*.iso') do set setupiso=/%%i
if not exist %~dp0boot\boot.wim %~dp0bin\7z.exe e -oboot -aoa  %1 sources/boot.wim


:: 获取管理员权限运行批处理
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
goto UACPrompt
) else ( goto gotAdmin )
:UACPrompt
echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
"%temp%\getadmin.vbs" 1>nul 2>nul
exit /b
:gotAdmin
if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" ) 1>nul 2>nul

(
echo #!ipxe
echo set setupwim^= /boot/boot.wim
echo set setupiso^= %setupiso%
echo set httptimeout^= 6
echo set autounattend^=
echo isset ${proxydhcp/dhcp-server} ^&^& chain http://^${proxydhcp/dhcp-server}/app/winsetup/netinstall.${platform} proxydhcp=^${proxydhcp/dhcp-server} setupwim=${setupwim=} setupiso=${setupiso=} httptimeout=${httptimeout=} autounattend=${autounattend=} ^|^|
echo chain http://^${next-server}/app/winsetup/netinstall.${platform} proxydhcp=^${next-server} setupwim=${setupwim=} setupiso=${setupiso=} httptimeout=${httptimeout=} autounattend=${autounattend=} 
) >%~dp0app/winsetup/netinstall.ipxe
(
echo [0]
echo name=微软原版安装
echo icon=iso
echo setupwim=/boot/boot.wim
echo setupiso=%setupiso%
echo command=Q:\\setup.exe
echo httptimeout=6
echo formatmbr=
echo formatgpt=
echo p2p=
echo command=
echo autounattend=
echo serverip=
)>%~dp0app\winsetup\netinstall.ini

(
echo [arch]
echo 00007=ipxe.efi
echo [dhcp]
echo start=1
echo proxydhcp=1
echo httpd=0
echo bind=1
echo poolsize=998
echo root=%~dp0
echo filename=ipxe.bios
echo altfilename=/app/winsetup/netinstall.ipxe
)>%~dp0bin\config.INI
start "" /min %~dp0bin\hfs.exe -c active=yes -a %~dp0bin\myhfs.ini
for /f %%a in ('dir /b/a-d *.*') do start "" /min %~dp0bin\hfs.exe %%a
start "" /min %~dp0bin\hfs.exe  %~dp0app imgs isos vhds pe wims wim boot
start ""  %~dp0bin\pxesrv.exe
exit
