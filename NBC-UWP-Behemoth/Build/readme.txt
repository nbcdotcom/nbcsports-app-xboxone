Must set environment config before running, see:

psakefile-environment.ps1
And update if the VS2017 version being used is different to professional

To produce a CI build (no versioning): 

.\psake.ps1 .\flavors.ps1 ProductionCI 


To produce a CD build (with versioning):

.\psake.ps1 .\flavors.ps1 ProductionCD


To customise the build version and/or build number and/or configURL (All optional! will build without, defaulting to stage!):

 .\psake.ps1 .\psakefile.ps1 CD -properties @{
    'solutionFileName' = 'NBC-UWP.sln'
    'build_platform' = 'x64'
    'configuration'  = 'Release'
    'project_name'   = 'NBC-UWP-Behemoth'
    'app_name'       = 'NBC'
    'product_id'     = 'ea010573-b5f9-4f81-97d8-47ec366f0586'
    'display_name'   = 'NBC-UWP-Behemoth'
    'buildVersion'   = '0.2'
    'buildNumber'    = '12345'
}
