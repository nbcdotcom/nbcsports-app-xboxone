@echo off
call %1
echo msbuild %2 /p:Configuration="%3" /p:Platform="%4" /v:q /p:UapAppxPackageBuildMode=%5
msbuild %2 /p:Configuration="%3" /p:Platform="%4" /v:q /p:UapAppxPackageBuildMode=%5