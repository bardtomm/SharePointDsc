function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)] [System.String] $Name,
        [parameter(Mandatory = $false)] [System.String] $WebApplication,
        [parameter(Mandatory = $false)] [System.Boolean] $Enabled,
        [parameter(Mandatory = $false)] [System.String] $Schedule,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Getting timer job settings"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        
        try {
            $spFarm = Get-SPFarm
        } catch {
            Write-Verbose -Verbose "No local SharePoint farm was detected. Timer job settings will not be applied"
            return $null
        }

        # Get a reference to the timer job
        if ($params.ContainsKey("WebApplication")) {
            $timerjob = Get-SPTimerJob $params.Name -WebApplication $params.WebApplication
        } else {
            $timerjob = Get-SPTimerJob $params.Name
        }

        # Check if timer job if found
        if ($timerjob -eq $null) { return $null }
        
        if ($timerjob.WebApplication.Name -eq $null) {
            # Timer job is not associated to web application
            return @{
                # Set the timer job settings
                Name = $params.Name
                Enabled = -not $timerjob.IsDisabled
                Schedule = $timerjob.Schedule
                InstallAccount = $params.InstallAccount
            }
        } else {
            # Timer job is associated to web application
            return @{
                # Set the timer job settings
                Name = $params.Name
                WebApplication = $timerjob.WebApplication.Name
                Enabled = -not $timerjob.IsDisabled
                Schedule = $timerjob.Schedule
                InstallAccount = $params.InstallAccount
            }
        }
    }

    return $result
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)] [System.String] $Name,
        [parameter(Mandatory = $false)] [System.String] $WebApplication,
        [parameter(Mandatory = $false)] [System.Boolean] $Enabled,
        [parameter(Mandatory = $false)] [System.String] $Schedule,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Setting timer job settings"

    Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        try {
            $spFarm = Get-SPFarm
        } catch {
            throw "No local SharePoint farm was detected. Timer job settings will not be applied"
            return
        }
        
        Write-Verbose -Message "Start update"

        # Set the timer job settings
        if ($params.ContainsKey("Enabled")) { 
            # Enable/Disable timer job
            if ($params.Enabled) {
                Write-Verbose -Verbose "Enable timer job $($params.Name)"
                if ($params.ContainsKey("WebApplication")) {
                    Enable-SPTimerJob $params.Name -WebApplication $params.WebApplication
                } else {
                    Enable-SPTimerJob $params.Name
                }
            } else {
                Write-Verbose -Verbose "Disable timer job $($params.Name)"
                if ($params.ContainsKey("WebApplication")) {
                    Disable-SPTimerJob $params.Name -WebApplication $params.WebApplication
                } else {
                    Disable-SPTimerJob $params.Name
                }
            }
        }

        if ($params.ContainsKey("Schedule")) {
            # Set timer job schedule
            Write-Verbose -Verbose "Set timer job $($params.Name) schedule"
            if ($params.ContainsKey("WebApplication")) {
                try {
                    Set-SPTimerJob $params.Name -WebApplication $params.WebApplication -Schedule $params.Schedule -EA Stop
                } catch {
                    throw "Incorrect schedule format used. New schedule will not be applied."
                    return
                }
            } else {
                try {
                    Set-SPTimerJob $params.Name -Schedule $params.Schedule -EA Stop
                } catch {
                    throw "Incorrect schedule format used. New schedule will not be applied."
                    return
                }
            }
        }
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)] [System.String] $Name,
        [parameter(Mandatory = $false)] [System.String] $WebApplication,
        [parameter(Mandatory = $false)] [System.Boolean] $Enabled,
        [parameter(Mandatory = $false)] [System.String] $Schedule,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Testing timer job settings"
    $CurrentValues = Get-TargetResource @PSBoundParameters

    if ($null -eq $CurrentValues) { return $false }

    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters
}

Export-ModuleMember -Function *-TargetResource
