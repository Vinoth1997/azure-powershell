# Login to Azure
Connect-AzAccount

# CSV input file
$csvFile = "C:\Scripts\snapshots.csv"

# Import CSV
$snapshots = Import-Csv -Path $csvFile

foreach ($snapshot in $snapshots) {

    $snapshotName = $snapshot.SnapshotName
    $resourceGroup = $snapshot.ResourceGroupName
    $subscription = $snapshot.Subscription

    Write-Host "Processing snapshot: $snapshotName" -ForegroundColor Cyan
    Write-Host "Resource Group: $resourceGroup"
    Write-Host "Subscription: $subscription"

    try {
        # Select subscription
        Set-AzContext -Subscription $subscription -ErrorAction Stop

        # Check whether snapshot exists
        $snapshotObj = Get-AzSnapshot `
            -ResourceGroupName $resourceGroup `
            -SnapshotName $snapshotName `
            -ErrorAction SilentlyContinue

        if ($null -eq $snapshotObj) {
            Write-Host "Snapshot not found: $snapshotName" -ForegroundColor Yellow
            continue
        }

        # Delete snapshot
        Remove-AzSnapshot `
            -ResourceGroupName $resourceGroup `
            -SnapshotName $snapshotName `
            -Force `
            -ErrorAction Stop

        Write-Host "Deleted successfully: $snapshotName" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to delete: $snapshotName" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }

    Write-Host "----------------------------------------"
}