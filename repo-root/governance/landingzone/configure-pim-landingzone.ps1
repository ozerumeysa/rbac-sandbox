# Install module if needed
Install-Module Microsoft.Graph -Scope CurrentUser -Force

# Connect to Graph
Connect-MgGraph -Scopes "PrivilegedAccess.ReadWrite.AzureADGroup", "Group.ReadWrite.All"

# Variables
$groupName = "LandingZone-Owner"
$approverGroup = "Approvers-Platform"

# Get group IDs
$group = Get-MgGroup -Filter "DisplayName eq '$groupName'"
$approver = Get-MgGroup -Filter "DisplayName eq '$approverGroup'"

# Enable PIM eligible assignment
$params = @{
    "principalId" = $null   # Auto-managed by PIM
    "resourceId" = $group.Id
    "roleDefinitionId" = "member"  # member of group
    "scheduleInfo" = @{
        "startDateTime" = (Get-Date).ToString("o")
        "expiration" = @{
            "type" = "AfterDuration"
            "duration" = "PT4H"  # 4 hours
        }
    }
    "status" = "Eligible"
}
New-MgPrivilegedAccessGroupEligibilityScheduleRequest -GroupId $group.Id -BodyParameter $params

# Configure approval settings
$settings = @{
    "approvalSettings" = @{
        "isApprovalRequired" = $true
        "isApprovalRequiredForExtension" = $false
        "isRequestorJustificationRequired" = $true
        "approvalType" = "SingleStage"
        "approvalStages" = @(
            @{
                "approvalStageTimeOutInDays" = 1
                "isApproverJustificationRequired" = $false
                "escalationEnabled" = $false
                "primaryApprovers" = @(
                    @{
                        "id" = $approver.Id
                        "type" = "Group"
                    }
                )
            }
        )
    }
}

Update-MgPrivilegedAccessGroupSetting -GroupId $group.Id -BodyParameter $settings