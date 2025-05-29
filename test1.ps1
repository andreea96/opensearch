$username = "master"
$password = "master*"
$pair = "${username}:${password}"
$encodedCreds = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($pair))
$authHeader = "Basic $encodedCreds"
$headers = @{
Authorization = "Basic $encodedCreds"
}
function getContentForXlsx {
	param([string]$filePath)
	$excel = New-Object -ComObject Excel.Application
	$workbook = $excel.Workbooks.Open()
	$sheet = $workbook.Sheets.Item(1)
	# Extrage toate celulele ca stringuri
	$range = $sheet.UsedRange
	foreach ($row in $range.Rows) {
		$line = ""
		foreach ($cell in $row.Columns) {
			$line += $cell.Text + " "
		}
		$content+=$line
	}

	#Write-Output $content.Trim()
	$workbook.Close($false)
	$excel.Quit()
	return $content
}

function indexFile {
	param([string]$filePath)
	try{
		if([System.IO.Path]::GetExtension($filePath) -eq ".txt") {
			$content = Get-Content $filePath -Raw
		}
		if([System.IO.Path]::GetExtension($filePath) -eq ".xlsx") {
			$content = getContentForXlsx -filePath $filePath
		}

	} catch {
       Write-Host "Eroare la extragerea continului, nu s-a indexat." -ForegroundColor Red
    }
	
	if($content -eq ""){
		Write-Host "Fisier gol. Nu se indexeaza!" -ForegroundColor Red
	}
	$content_clean = $content -replace "(\r\n|\r|\n)", " "
	$id = $filePath.Replace("\", "")

	$jsonBody = @{
        location = $filePath;
        content = $content_clean.Trim()
    } | ConvertTo-Json
	$jsonBody1 = @{
        location = "location";
        content = "test"
    } | ConvertTo-Json

	try {
		$headers = @{
			"Content-Type" = "application/json"
			"Authorization" = $authHeader
		}
		Write-Output $jsonBody
		$resp = curl -Uri http://localhost:9200/test1/_doc/$id `
		 -Method POST `
		 -ContentType "application/json" `
		 -Body $jsonBody 
		Write-Output "Data sent successfully"
	}

	catch {
       Write-Error "Failed to send data to Elasticsearch: $_"
    }
}

# read from folder 
$folderPath = Read-Host "Introdu calea către folder"

if (-not (Test-Path $folderPath)) {
    Write-Error "Calea nu există!"
    exit
}

Get-ChildItem -Recurse -Path $folderPath | Where-Object {
    $_.Extension -in ".txt", ".csv", ".xlsx"
} | ForEach-Object {
    Write-Output "Indexarea Fisier: $($_.Name)"
	indexFile -filePath  $($_.FullName)
	#"C:\\Users\\Andreea\\OneDrive\\Desktop\\test_opensearch_files\\test.txt"
}

Read-Host "Apasă Enter pentru a închide"


