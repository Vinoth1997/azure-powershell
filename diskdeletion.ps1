# Login to Azure
Connect-AzAccount

# CSV input file
$csvFile = "C:\Scripts\disks.csv"

# Import CSV
$disks = Import-Csv -Path $csvFile

foreach ($disk in $disks) {

    $diskName     = $disk.DiskName
    $resourceGroup = $disk.ResourceGroupName
    $subscription = $disk.Subscription

    Write-Host "Processing: $diskName" -ForegroundColor Cyan

    try {
        # Set subscription
        Set-AzContext -Subscription $subscription -ErrorAction Stop

        # Get disk
        $diskObj = Get-AzDisk `
            -ResourceGroupName $resourceGroup `
            -DiskName $diskName `
            -ErrorAction SilentlyContinue

        if ($null -eq $diskObj) {
            Write-Host "Disk not found: $diskName" -ForegroundColor Yellow
            continue
        }

        # Check whether disk is attached
        if ($null -eq $diskObj.ManagedBy) {

            Write-Host "Disk is UNATTACHED. Deleting: $diskName" -ForegroundColor Red

            Remove-AzDisk `
                -ResourceGroupName $resourceGroup `
                -DiskName $diskName `
                -Force `
                -ErrorAction Stop

            Write-Host "Deleted successfully: $diskName" -ForegroundColor Green
        }
        else {
            Write-Host "Disk is ATTACHED - skipping: $diskName" -ForegroundColor Yellow
            Write-Host "Attached to: $($diskObj.ManagedBy)"
        }
    }
    catch {
        Write-Host "Failed: $diskName" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }

    Write-Host "----------------------------------------"
}