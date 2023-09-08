function ListPrintJobs {
    $printers = Get-Printer 
    #$printers = Get-Printer | Where-Object{$_.PortName -match "IP_.*"}

	if ($printers.Count -eq 0) { throw "No printer found" }

	foreach ($printer in $printers) {
		$PrinterName = $printer.Name
		$printjobs = Get-PrintJob -PrinterObject $printer
		if ($printjobs.Count -eq 0) {
			$PrintJobs = "none"
		} else {
			$PrintJobs = "$printjobs"
		}
		New-Object PSObject -Property @{ Printer=$PrinterName; Jobs=$PrintJobs }
	}
}


ListPrintJobs | Where-Object{$_.Jobs -ne "none"}| Format-Table -property Printer,Jobs


