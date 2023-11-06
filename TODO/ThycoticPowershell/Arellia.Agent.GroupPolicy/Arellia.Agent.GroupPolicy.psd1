@{
GUID = '9a673813-74f8-4626-902b-0e1e905d9571'
Author = 'Thycotic'
CompanyName = 'Thycotic'
Copyright = 'Copyright 2013- Arellia Corporation. All rights reserved'
Description = ''
ModuleVersion="2.0.0.0"

PowerShellVersion="2.0"
CLRVersion="4.0"
#DotNetFrameworkVersion = ''
#ProcessorArchitecture = ''

# Assemblies that must be loaded prior to importing this module
RequiredAssemblies = '..\..\Agents\Agent\Arellia.Agent.Management.dll', '..\..\Agents\Agent\Arellia.Core.dll', '..\..\Agents\Agent\Arellia.Agent.dll'

# Modules that must be imported into the global environment prior to importing this module
#RequiredModules = 'Arellia.Agent'

NestedModules = "..\..\Agents\GroupPolicy\Arellia.Agent.GroupPolicy.dll"



# Script files (.ps1) that are run in the caller's environment prior to importing this module
ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
FormatsToProcess = @()

# Modules to import as nested modules of the module specified in ModuleToProcess
# = 

}

