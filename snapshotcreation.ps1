# Login to Azure
Connect-AzAccount

# CSV input file
$csvFile = "C:\Scripts\vms.csv"

# Import CSV
$vms = Import-Csv -Path $csvFile

foreach ($vmInput in $vms) {

    $vmName        = $vmInput.VMName
    $resourceGroup = $vmInput.ResourceGroupName
    $subscription  = $vmInput.Subscription

    Write-Host ""
    Write-Host "Processing VM: $vmName" -ForegroundColor Cyan
    Write-Host "Resource Group: $resourceGroup"
    Write-Host "Subscription: $subscription"

    try {

        # Set subscription
        Set-AzContext -Subscription $subscription -ErrorAction Stop

        # Get VM
        $vm = Get-AzVM `
            -ResourceGroupName $resourceGroup `
            -Name $vmName `
            -ErrorAction Stop

        # --------------------------------------------------
        # OS DISK
        # --------------------------------------------------

        $osDiskName = $vm.StorageProfile.OsDisk.Name

        Write-Host ""
        Write-Host "Creating snapshot for OS disk: $osDiskName" -ForegroundColor Yellow

        $osDisk = Get-AzDisk `
            -ResourceGroupName $resourceGroup `
            -DiskName $osDiskName `
            -ErrorAction Stop

        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

        $snapshotName = "$vmName-$osDiskName-Snapshot-$timestamp"

        $snapshotConfig = New-AzSnapshotConfig `
            -SourceUri $osDisk.Id `
            -Location $osDisk.Location `
            -CreateOption Copy `
            -SkuName Standard_LRS

        New-AzSnapshot `
            -ResourceGroupName $resourceGroup `
            -SnapshotName $snapshotName `
            -Snapshot $snapshotConfig `
            -ErrorAction Stop

        Write-Host "OS snapshot created: $snapshotName" -ForegroundColor Green


        # --------------------------------------------------
        # DATA DISKS
        # --------------------------------------------------

        $dataDisks = $vm.StorageProfile.DataDisks

        if ($dataDisks.Count -eq 0) {

            Write-Host "No data disks attached to VM: $vmName" -ForegroundColor Gray

        }
        else {

            foreach ($dataDisk in $dataDisks) {

                $dataDiskName = $dataDisk.Name

                Write-Host ""
                Write-Host "Creating snapshot for data disk: $dataDiskName" -ForegroundColor Yellow

                $disk = Get-AzDisk `
                    -ResourceGroupName $resourceGroup `
                    -DiskName $dataDiskName `
                    -ErrorAction Stop

                $snapshotName = "$vmName-$dataDiskName-Snapshot-$timestamp"

                $snapshotConfig = New-AzSnapshotConfig `
                    -SourceUri $disk.Id `
                    -Location $disk.Location `
                    -CreateOption Copy `
                    -SkuName Standard_LRS

                New-AzSnapshot `
                    -ResourceGroupName $resourceGroup `
                    -SnapshotName $snapshotName `
                    -Snapshot $snapshotConfig `
                    -ErrorAction Stop

                Write-Host "Data disk snapshot created: $snapshotName" -ForegroundColor Green
            }
        }

    }
    catch {

        Write-Host ""
        Write-Host "FAILED: $vmName" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }

    Write-Host "============================================"
}
