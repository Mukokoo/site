param(
    $uri,
    $bd,
    $pg
)

$ProgressPreference = 'SilentlyContinue'

curl.exe (irm "https://raw.githubusercontent.com/ScoopInstaller/Extras/master/bucket/$pg.json").architecture.'64bit'.url -o"./$pg.zip"
Expand-Archive .\$pg.zip -DestinationPath .

$pages = (irm "$uri/sitemap.xml").ChildNodes.url.loc -join ','

& "./$pg/$pg.exe" $uri -O "./out" -%v | out-null

Move-Item ./out/$($uri -replace 'https://')/* . -Force

Remove-Item ./out/, ./$pg.zip, ./$pg/, file_id.diz -Recurse -Force

Get-ChildItem *.html | ForEach-Object {
    $content = Get-Content $PSItem.FullName

    # remove large footer banner, the "made with $bd" clearly suffices --'
    $content = $content -replace [regex]::escape('<div class="jw-strip jw-strip--color-default jw-strip--padding-end" >'), '<div style="display:none">'

    $content = $content -replace '</head>', '<style>.js-ads{display: none}</style></head>'

    # $pg does not include background image, so the following injects it back into the css
    $live = Invoke-RestMethod "$uri/$($PSItem.BaseName)"

    $bg_line = $live -split "`n" | Where-Object {$_ -like "*background-image*"}

    $background_image = ($bg_line | Select-String -Pattern 'background-image: url\(&#039;(.*?)&#039;\);' -AllMatches | ForEach-Object { $_.Matches }).Value

    $content = $content -replace 'background-position', ($background_image + 'background-position')

    # replace favicon
    $favicon_line = $content -split "`n" | Where-Object {$_.trim() -like "*rel=`"shortcut icon`"*"} 
    $content = ($content -split "`n") -replace ([Regex]::Escape($favicon_line)), '<link rel="shortcut icon" href="https://primary.jwwb.nl/public/g/a/s/temp-lgrjllrfpibgzsmnztdh/ojy3fv/websitelogo-1.png?enable-io=true&amp;enable=upscale&amp;width=100">'
    
    # remove mobile (burger) menu
    $content = $content -replace 'class="jw-mobile-menu__button jw-mobile-toggle"', 'class="jw-mobile-menu__button jw-mobile-toggle" style="display: none"'

    # remove menu
    $content = $content -replace 'class="menu jw-menu-copy"', 'class="menu jw-menu-copy" style="display: none"'

    # write the changes back
    Set-Content -Path $PSItem.FullName -Value $content
}