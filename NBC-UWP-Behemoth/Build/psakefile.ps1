#requires -Version 3
. '.\psakefile-tools.ps1'
. '.\psakefile-environment.ps1'

Properties {
  $solutionFileName = $null
  $build_platform = $null
  $configuration = $null
  $project_name = $null
  $app_name = $null
  $display_name = $null
  $product_id = $null
  $buildVersion = $null
  $buildNumber = $null
  $appxBuildMode = $null
  $url = $null
}

$release = $null

Task VerifyBuildProperties {
  Assert ($solutionFileName -ne $null) 'Solution file name should not be null'
  Assert ($build_platform -ne $null) 'Build platform should not be null'
  Assert ($configuration -ne $null) 'Configuration should not be null'
  Assert (Get-MSBuildLocation -ne $null) 'MSBuild path should not be null'
  Assert ($appxBuildMode -ne $null) 'appxBuildMode should not be null, use "Test" or "StoreUpload"'
  Assert ($url -ne $null) 'url should not be null, set to the url of the HTML app'
}

Task VerifyTestProperties {
  Assert ($project_name -ne $null) 'Project Name should not be null'
  Assert ($VSTest_path -ne $null) 'VSTest Path should not be null'
}

Task VerifyVersionProperties -Depends VerifyTestProperties {
  Assert ($app_name -ne $null) 'App Name should not be null'
  Assert ($display_name -ne $null) 'Display Name should not be null'
  Assert ($product_id -ne $null) 'Product Id should not be null'
}

# our default task, which is used if no task is specified
Task Default -Depends Build

Task CI -Depends Version, Build

Task CD -Depends Version, Build, Package

Task Build -Depends VerifyBuildProperties, Clean, RestorePackages {
  Write-Host -Object 'Building solution' -ForegroundColor DarkCyan
  $solPath = Get-SolutionPath -solutionName $solutionFileName
  Exec {
    & .\msbuildWrapper.bat (Get-DevToolsLocation) ($solPath) $configuration $build_platform $appxBuildMode
  }
  $file = Get-AppxPackageLocation -projectName $project_name
  Write-Host -Object "`n`n`nBuild complete, Appx ready for testing at $file" -ForegroundColor Green

  $appxuppfile = Get-AppxUploadFile -projectName $project_name
  if (($appxuppfile -ne $null))
  {
    if ($appxBuildMode -eq "Test")
    {
        Remove-Item $appxuppfile
        Write-Host -Object "`nAppxUpload was found at $appxuppfile but we're in Test build so removing" -ForegroundColor DarkCyan
    }
    else
    {
        Write-Host -Object "`nAppxUpload ready for publishing at $appxuppfile" -ForegroundColor Green
    }
  }
}

Task Package -Depends Build {
  $source = Get-AppxPackageDirectory -projectName $project_name
  $packagesPath = (Get-SolutionFolder) + '\' + $project_name + '\AppPackages\'
  $zipfilename = "$packagesPath" + "package.zip"

  if (Test-Path $zipfilename)
  {
    Remove-Item $zipfilename
  }

  Write-Host -Object "Zipping contents of $source to $zipfilename" -ForegroundColor DarkCyan
  ZipFiles -zipfilename $zipfilename -sourcedir $source 
}

Task Publish -Depends Package {
  $packagesPath = (Get-SolutionFolder) + '\' + $project_name + '\AppPackages\'
  $zipfilename = "$packagesPath" + "package.zip"
  Upload-To-HockeyApp-Hoch -Version $release -zipFile $zipfilename
}

Task Clean {
  Write-Host -Object 'Cleaning solution' -ForegroundColor DarkCyan
  Exec {
    & (Get-MSBuildLocation) (Get-SolutionPath -solutionName $solutionFileName) /p:Configuration="$configuration" /p:Platform="$build_platform" /v:q /t:Clean
  }
}

Task Version -Depends VerifyVersionProperties {
  $appx_file_path = Get-ProjectFilePath -projectName $project_name -fileName 'Package.appxmanifest'
  $XMLfile = Get-ProjectFileXmlObject -filePath $appx_file_path
  $version = $XMLfile.Package.Identity.Version
  Write-Host -Object "Current version number = $version"
  if ($buildVersion -eq $null)
  {
    $major = $version.Split('.')[0]
    $minor = $version.Split('.')[1]
  }
  else
  {
  $major = $buildVersion.Split('.')[0]
  $minor = $buildVersion.Split('.')[1]
  }
  $release = $buildNumber
  if ($release -eq $null)
  {
    $release = Get-Date -Format Mdd

    $solutionFolder = Get-SolutionFolder

    if (!(Test-Path "$solutionFolder\$release.num")) { '0' | Out-File "$solutionFolder\$release.num" }

    $revision = [convert]::ToInt32([IO.File]::ReadAllText("$solutionFolder\$release.num"))
    Remove-Item "$solutionFolder\*.num"
    $revision++;
    if ($revision -gt 9)
    {
        $minor = [convert]::ToInt32($minor)
        $minor++
        $revision = 0
    }
    $revision | Out-File "$solutionFolder\$release.num"

    $release = $release + $revision
  }
  $NETbuildNumber = 0
  $version = "$major.$minor.$release.$NETbuildNumber"
  Write-Host -Object "Updating appxmanifest file with version number $version" -ForegroundColor DarkCyan

  #Save the new version number
  $XMLfile.Package.Identity.Version = $version
  $XMLfile.Package.Identity.Name = $app_name
  $XMLfile.Package.Applications.Application.VisualElements.DisplayName = $display_name
  $XMLfile.Package.PhoneIdentity.PhoneProductId = $product_id
  $XMLfile.Package.Properties.DisplayName = $display_name
  $XMLfile.Package.Applications.Application.StartPage = $url
  $XMLfile.Package.Applications.Application.ApplicationContentUriRules.Rule[0].Match = $url

  # set the file as read write and save
  Set-ItemProperty ($appx_file_path) -Name IsReadOnly -Value $false
  $XMLfile.save($appx_file_path)
  Write-Host -Object 'Updated the appxmanifest file' -ForegroundColor DarkCyan

  $association_file_path = Get-ProjectFilePath -projectName $project_name -fileName 'Package.StoreAssociation.xml'
  if (Test-Path "$association_file_path") 
  {
    $XMLfile = Get-ProjectFileXmlObject -filePath $association_file_path

    # set the file as read write and save
    Set-ItemProperty ($association_file_path) -Name IsReadOnly -Value $false
    $XMLfile.save($association_file_path)
    Write-Host -Object 'Updated the store association file' -ForegroundColor DarkCyan
  }
}

Task RestorePackages {
  Write-Host -Object 'Start restoring Nuget packages' -ForegroundColor DarkCyan
  $nuget_executable_file_path = $PSScriptRoot + '\NuGet.exe'
  Exec {
    &($nuget_executable_file_path) restore (Get-SolutionPath -solutionName $solutionFileName) -NoCache
  }
}

Task Test -Depends VerifyTestProperties {
  $file = Get-AppxPackageLocation -projectName $project_name
  Write-Host -Object "Starting tests with test appx package $file" -ForegroundColor DarkCyan
  $output = (&($VSTest_path) $file)
  Write-Host $output
  if (!($output -like '*Test Run Successful*')) {
    throw 'Test: Unit test run unsuccessful'
  }
}

Task Validate {
  $reportOutput = $PSScriptRoot + '\report.xml'
  if (Test-Path $reportOutput)
  {
    Remove-Item $reportOutput
  }
  $file = Get-AppxPackageLocation -projectName $project_name
  Exec {
    &('C:\Program Files (x86)\Windows Kits\10\App Certification Kit\appcert.exe') reset
  }
  Write-Host 'Starting Validation of appx package ' + $file -ForegroundColor DarkCyan
  Exec {
    &('C:\Program Files (x86)\Windows Kits\10\App Certification Kit\appcert.exe') test -appxpackagepath $file -reportoutputpath $reportOutput
  }
}
