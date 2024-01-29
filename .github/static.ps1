param(
    $uri,
    $bd,
    $pg
)

$ProgressPreference = 'SilentlyContinue'

curl (irm "https://raw.githubusercontent.com/ScoopInstaller/Extras/master/bucket/$pg.json").architecture.'64bit'.url -o $pg.zip
Expand-Archive .\$pg.zip -DestinationPath .

$pages = (irm "$uri/sitemap.xml").ChildNodes.url.loc -join ','

& "./$pg/$pg.exe" $uri -O "./out" -%v | out-null

Move-Item ./out/$($uri -replace 'https://')/* . -Force

Remove-Item ./out/, ./$pg.zip, ./$pg/, file_id.diz -Recurse -Force

Get-ChildItem *.html | ForEach-Object {
    $content = Get-Content $PSItem.FullName
    $content = $content -replace [regex]::escape('<div id="jw-credits-tool">'), '<div style="display:none">'
    Set-Content -Path $PSItem.FullName -Value $content
}