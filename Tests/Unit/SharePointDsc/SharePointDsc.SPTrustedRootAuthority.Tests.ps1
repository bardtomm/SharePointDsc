[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string] 
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
                                         -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
                                         -Resolve)
)

Import-Module -Name (Join-Path -Path $PSScriptRoot `
                                -ChildPath "..\UnitTestHelper.psm1" `
                                -Resolve)

$Global:SPDscHelper = New-SPDscUnitTestHelper -SharePointStubModule $SharePointCmdletModule `
                                              -DscResource "SPTrustedRootAuthority"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope


        Context -Name "When TrustedRootAuthority should exist and does exist in the farm." -Fixture {
          
            $testParams = @{
                Name = "CertIdentifier"
                Certificate = "770515261D1AB169057E246E0EE6431D557C3AFB"
                Ensure = "Present"
            }

            Mock -CommandName Get-ChildItem -MockWith {
                
                $cert = New-Object 
                return @(

                    @{
                        Subject = "CN=CertName"
                        Thumbprint = $testParams.Certificate
                    }
                    @{
                        Subject = "CN=SomeOtherCert"
                        Thumbprint = "770515261D1AB169057E246E0EE6431D557C3AFC"
                    }
                    )
            }
            
            Mock -CommandName Get-SPTrustedRootAuthority -MockWith { 
                return @{
                    Name = $testParams.Name
                    Certificate = @{
                        Thumbprint = $testParams.Certificate
                    }
                }
            }

            Mock -CommandName Set-SPTrustedRootAuthority -MockWith {
                return @{
                    Name = $testParams.Name
                    Certificate = @{
                        Thumbprint = $testParams.Certificate
                    }
                }
            }

            It "Should return Present from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"  
            }

            It "Should return true when the Test method is called" {
                Test-TargetResource @testParams | Should Be $true
            }

            It "Should Update the SP Trusted Root Authority in the set method" {
             ##   Set-TargetResource @testParams
             ##   Assert-MockCalled Get-SPTrustedRootAuthority -Times 1
             ##   Assert-MockCalled Set-SPTrustedRootAuthority -Times 1    
            }
        }

         Context -Name "When TrustedRootAuthority should exist and does exist in the farm, but has incorrect certificate." -Fixture {
          
            $testParams = @{
                Name = "CertIdentifier"
                Certificate = "770515261D1AB169057E246E0EE6431D557C3AFB"
                Ensure = "Present"
            }
            
            Mock -CommandName Get-SPTrustedRootAuthority -MockWith { 
                return @{
                    Name = $testParams.Name
                    Certificate = @{
                        Thumbprint = "770515261D1AB169057E246E0EE6431D557C3AFC"
                    }
                }
            }

            Mock -CommandName Get-ChildItem -MockWith {
                return @(
                    @{
                        Subject = "CN=CertName"
                        Thumbprint = $testParams.Certificate
                    }
                    @{
                        Subject = "CN=SomeOtherCert"
                        Thumbprint = "770515261D1AB169057E246E0EE6431D557C3AFC"
                    }
                    )
            }

            Mock -CommandName Set-SPTrustedRootAuthority -MockWith {

            }

            It "Should return Present from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"  
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should create a new service application in the set method" {
              ##  Set-TargetResource @testParams
              ##  Assert-MockCalled Get-SPTrustedRootAuthority -Times 1
              ##  Assert-MockCalled Set-SPTrustedRootAuthority -Times 1    
            }
        }

        Context -Name "When TrustedRootAuthority should exist and doesn't exist in the farm, but has an invalid certificate." -Fixture {
          
            $testParams = @{
                Name = "CertIdentifier"
                Certificate = "770515261D1AB169057E246E0EE6431D557C3AFB"
                Ensure = "Present"
            }
            
            Mock -CommandName Get-SPTrustedRootAuthority -MockWith { 
                return $null
            }

            Mock -CommandName Get-ChildItem -MockWith {
               return $null
            }

            Mock -CommandName Set-SPTrustedRootAuthority -MockWith {

            }

            It "Should return Absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"  
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw a Certificate not found error" {
                { Set-TargetResource @testParams } | Should Throw "Certificate not found in the local Certificate Store"
                
            }
        }

        
        Context -Name "When TrustedRootAuthority should exist and doesn't exist in the farm." -Fixture {
          
            $testParams = @{
                Name = "CertIdentifier"
                Certificate = "770515261D1AB169057E246E0EE6431D557C3AFB"
                Ensure = "Present"
            }

            Mock -CommandName Get-ChildItem -ParameterFilter { $Path -eq "Cert:\LocalMachine\My" } -MockWith {
                return @(
                    @{
                        Subject = "CN=CertIdentifier"
                        Thumbprint = $testParams.Certificate
                    }
                )
            }

            Mock -CommandName Get-SPTrustedRootAuthority -MockWith { 
                return $null
            }

            Mock -CommandName  New-SPTrustedRootAuthority -MockWith {

            }

            It "Should return Absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"  
            }

            It "Should return true when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should create a new service application in the set method" {
        ##        Set-TargetResource @testParams
        ##        Assert-MockCalled Get-ChildItem -Times 1
        ##        Assert-MockCalled New-SPTrustedRootAuthority -Times 1    
            }

        }

        Context -Name "When TrustedRootAuthority shouldn't exist and does exist in the farm." -Fixture {
          
            $testParams = @{
                Name = "CertIdentifier"
                Certificate = "770515261D1AB169057E246E0EE6431D557C3AFB"
                Ensure = "Absent"
            }

            Mock -CommandName Get-ChildItem -MockWith {
                return @{
                    Thumbprint = $testParams.Certificate
                }
            }

            Mock -CommandName  Remove-SPTrustedRootAuthority -MockWith { }

            Mock -CommandName Get-SPTrustedRootAuthority -MockWith { 
                return @{
                    Name = $testParams.Name
                    Certificate = @{
                        Thumbprint = $testParams.Certificate
                    }
                }
            }

            Mock -CommandName Set-SPTrustedRootAuthority -MockWith {

            }

            It "Should return Present from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"  
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }
            It "Should remove the Trusted Root Authority" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPTrustedRootAuthority -Times 1    
            }

        }

        Context -Name "When TrustedRootAuthority shouldn't exist and doesn't exist in the farm." -Fixture {
          
            $testParams = @{
                Name = "CertIdentifier"
                Certificate = "770515261D1AB169057E246E0EE6431D557C3AFB"
                Ensure = "Absent"
            }

            Mock -CommandName Get-ChildItem -MockWith {
                return @{
                    Thumbprint = $testParams.Certificate
                }
            }

            Mock -CommandName  Remove-SPTrustedRootAuthority -MockWith { }

            Mock -CommandName Get-SPTrustedRootAuthority -MockWith { 
                return $null
            }

            Mock -CommandName Set-SPTrustedRootAuthority -MockWith {

            }

            It "Should return Absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"  
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $true
            }
            It "Should remove the Trusted Root Authority" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPTrustedRootAuthority -Times 1    
            }

        }

    }

}