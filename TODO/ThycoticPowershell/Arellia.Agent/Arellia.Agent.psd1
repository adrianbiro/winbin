@{
GUID = '65eeb685-dda0-49ed-b761-e7f25c5cfd3f'
Author = 'Thycotic'
CompanyName = 'Thycotic'
Copyright = 'Copyright 2012- Arellia Corporation. All rights reserved'
Description = ''
ModuleVersion="7.5.0.0"

PowerShellVersion="2.0"
CLRVersion="4.0"
#DotNetFrameworkVersion = ''
#ProcessorArchitecture = ''

NestedModules = Join-Path $psScriptRoot "..\..\Agents\Agent\Arellia.Agent.dll"

# Modules that must be imported into the global environment prior to importing this module
#RequiredModules = Join-Path $psScriptRoot "Arellia.Agent.dll"

# Assemblies that must be loaded prior to importing this module
RequiredAssemblies = Join-Path $psScriptRoot '..\..\Agents\Agent\Arellia.Agent.Management.dll'

# Script files (.ps1) that are run in the caller's environment prior to importing this module
ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
FormatsToProcess = 'Arellia.Agent.formats.ps1xml'

# Modules to import as nested modules of the module specified in ModuleToProcess
# = 


}

