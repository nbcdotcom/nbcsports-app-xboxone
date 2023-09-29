#requires -Version 3
function Get-SolutionFolder
{
  return (Get-Item $PSScriptRoot).Parent.FullName
}

function Get-SolutionPath
{
  param
  (
    [string]
    $solutionName
  )
  
  return ((Get-SolutionFolder) + "\$solutionName")
}

function Get-ProjectFilePath
{
  param
  (
    [string]
    $projectName,
   
    [string]
    $fileName
  )
  
  return ((Get-SolutionFolder) + "\$project_name\$fileName")
}

function Get-ProjectFileXmlObject
{
  param
  (
    [string]
    $filePath
  )
  
  
  $XMLfile = New-Object -TypeName XML
  $XMLfile.Load($filePath)
  return $XMLfile
}

function ZipFiles
{
    param
    (
    [string]
    $zipfilename,
    [string]
    $sourcedir
    )

   Compress-Archive -Path $sourcedir -DestinationPath $zipfilename
}

function Get-MSBuildLocation
{
  if (Test-Path $msbuild_prof_path)
  {
    return "$msbuild_prof_path"
  }
  else
  {
    return "$msbuild_com_path"
  }
}

function Get-DevToolsLocation
{
  if (Test-Path $devTools_prof_path)
  {
    return "$devTools_prof_path"
  }
  else
  {
    return "$devTools_com_path"
  }
}

function Get-CsProjFile
{
  param
  (
    [string]
    $projectName
  )

  return (Get-SolutionFolder) + '\' + $project_name + '\' + $project_name + '.csproj'
}

function Get-AppxPackageLocation
{
  param
  (
    [string]
    $projectName
  )

  $packagesPath = (Get-SolutionFolder) + '\' + $project_name + '\AppPackages\'
  return Get-ChildItem -Path $packagesPath -Directory |
  Sort-Object -Property CreationTime |
  Select-Object -Last 1 |
  Get-ChildItem -Filter '*.appx' |
  Select-Object -First 1 |
  ForEach-Object -Process {
    $_.FullName
  }
}

function Get-AppxPackageDirectory
{
  param
  (
    [string]
    $projectName
  )

  $packagesPath = (Get-SolutionFolder) + '\' + $project_name + '\AppPackages\'
  return Get-ChildItem -Path $packagesPath -Directory |
  Sort-Object -Property CreationTime |
  Select-Object -Last 1 |
  ForEach-Object -Process {
    $_.FullName
  }
}

function Get-AppxUploadFile
{
  param
  (
    [string]
    $projectName
  )

  $packagesPath = (Get-SolutionFolder) + '\' + $project_name + '\AppPackages\'
  return Get-ChildItem -Path $packagesPath -Filter '*.appxupload' |
  Sort-Object -Property CreationTime |
  Select-Object -First 1 |
  ForEach-Object -Process {
    $_.FullName
  }
}

function Get-AppxPackageZipFile
{
  param
  (
    [string]
    $projectName
  )

  $packagesPath = (Get-SolutionFolder) + '\' + $project_name + '\AppPackages\'
  return Get-ChildItem -Path $packagesPath -Directory |
  Sort-Object -Property CreationTime |
  Select-Object -Last 1 |
  ForEach-Object -Process {
    $_.FullName + ".zip"
  }
}

function Upload-To-HockeyApp-Hoch
{
    Param(
        [string]
        $version,
        [string]
        $zipFile
    )
     Exec {
    &($hoch_path) $zipFile /version $version
  }
}

function Upload-To-HockeyApp
{
    Param(
        [string]
        $HockeyAppAppID, 
        [string]
        $HockeyAppApiToken,
        [string]
        $version,
        [string]
        $zipFile
    )
 
    $create_url = "https://rink.hockeyapp.net/api/2/apps/$HockeyAppAppID/app_versions/new"
 
    $zip = $zipFile.BaseName
 
    $response = Invoke-RestMethod -Method POST -Uri $create_url  -Header @{ "X-HockeyAppToken" = $HockeyAppApiToken } -Body "{bundle_version = $version}"
 
    $update_url = "https://rink.hockeyapp.net/api/2/apps/$($HockeyAppAppID)/app_versions/$($response.id)"

    $fileBin = [IO.File]::ReadAllBytes($zipFile)
    $enc = [System.Text.Encoding]::GetEncoding("ISO-8859-1")
    $fileEnc = $enc.GetString($fileBin)
    $boundary = [System.Guid]::NewGuid().ToString()
    $LF = "`r`n"

    $bodyLines = (
        "--$boundary",
	    "content-transfer-encoding: base64",
	    "Content-Disposition: form-data; content-transfer-encoding: `"base64`"; name=`"ipa`"; filename=`" [System.IO.Path]::GetFileName $zipFile`"$LF",$fileEnc,
        "--$boundary",
        "Content-Disposition: form-data; name=`"status`"$LF","2",
        "--$boundary--$LF") -join $LF
	
    Invoke-RestMethod -Uri $update_url -Method PUT -Headers @{ "X-HockeyAppToken" = $HockeyAppApiToken } -ContentType "multipart/form-data; boundary=`"$boundary`""  -Body $bodyLines
}