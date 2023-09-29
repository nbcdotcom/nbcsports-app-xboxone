@echo off
call %1
msbuild %2 /p:Configuration="%3" /p:Platform="%4" /v:q /p:BuildAppxUploadPackageForUap=true