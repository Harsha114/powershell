Get-ADGroup -filter * -Properties * | Select Name,DistinguishedName,Description | Export-Csv c:\SecurityGroups.csv