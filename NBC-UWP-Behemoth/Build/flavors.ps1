#requires -Version 1
Task Default -Depends ProductionCI


Task ProductionCI {
  Invoke-psake psakefile.ps1 CI -properties @{
    'solutionFileName' = 'NBC-UWP.sln'
    'build_platform'   = 'x64'
    'configuration'    = 'Release'
    'project_name'     = 'NBC-UWP'
    'appxBuildMode'    = 'Test'
  }
}

Task ProductionCD {
  Invoke-psake psakefile.ps1 CD -properties @{
    'solutionFileName' = 'NBC-UWP.sln'
    'build_platform'   = 'x64'
    'configuration'    = 'Release'
    'project_name'     = 'NBC-UWP'
    'app_name'         = 'NBC'
    'product_id'       = 'ea010573-b5f9-4f81-97d8-47ec366f0586'
    'display_name'     = 'NBC-UWP'
    'appxBuildMode'    = 'StoreUpload'
  }
}

Task BetaCD {
  Invoke-psake psakefile.ps1 CD -properties @{
    'solutionFileName' = 'NBC-UWP.sln'
    'build_platform'   = 'x64'
    'configuration'    = 'Release'
    'project_name'     = 'NBC-UWP'
    'app_name'         = 'NBC'
    'product_id'       = 'ea010573-b5f9-4f81-97d8-47ec366f0586'
    'display_name'     = 'NBC-UWP'
    'appxBuildMode'    = 'Test'
  }
}
