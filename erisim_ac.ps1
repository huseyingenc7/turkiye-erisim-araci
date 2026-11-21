# Turkiye'de erisim engeli olan sitelere (Discord, Roblox, Wattpad vb.) erismek icin.
# GoodbyeDPI'i SERVIS KURMADAN calistirir.
#  1) Yerel DNS koprusunu (dns_kopru.ps1) acar: DNS sorgularini sifreli DNS'e iletir
#  2) Acik ag baglantilarinin DNS'ini gecici olarak 127.0.0.1 (kopru) + 1.1.1.1 (yedek) yapar
#  3) GoodbyeDPI'i "-5 --set-ttl 5" ayariyla acar
#  K tusuna basinca hepsini kapatir ve DNS ayarlarini eski haline dondurur.
#  hosts dosyasina DOKUNMAZ.
# Kullanim:  erisim_ac.ps1          -> ac
#            erisim_ac.ps1 -Kapat   -> sadece kapat / eski haline dondur
param([switch]$Kapat)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$dir      = Split-Path -Parent $MyInvocation.MyCommand.Path
$arch     = if ([Environment]::Is64BitOperatingSystem) { 'x86_64' } else { 'x86' }
$exe      = Join-Path $dir "$arch\goodbyedpi.exe"
$gdpiArgs = '-5 --set-ttl 5'
$kopru    = Join-Path $dir 'dns_kopru.ps1'
$dnsYedek = Join-Path $dir 'dns_yedek.json'
$kopruLog = Join-Path $dir 'kopru_log.txt'
$yedekDns = '1.1.1.1'

# Acilista kontrol edilecek siteler (sadece bilgi icin; hepsi zorunlu degil)
$kontrol = 'discord.com', 'www.roblox.com', 'www.wattpad.com'

function Yonetici { ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) }

function Kopru-Durdur {
  Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -match 'dns_kopru\.ps1' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
}

function DNS-Geri {
  if (-not (Test-Path $dnsYedek)) { return }
  $liste = @(Get-Content $dnsYedek -Raw | ConvertFrom-Json)
  foreach ($a in $liste) {
    try {
      # Once her seyi otomatige al, sonra eskiden elle yazilmis olanlari geri koy
      Set-DnsClientServerAddress -InterfaceAlias $a.Ad -ResetServerAddresses
      if ($a.Statik)  { Set-DnsClientServerAddress -InterfaceAlias $a.Ad -ServerAddresses ($a.Statik  -split '[ ,]+' | Where-Object { $_ }) }
      if ($a.Statik6) { Set-DnsClientServerAddress -InterfaceAlias $a.Ad -ServerAddresses ($a.Statik6 -split '[ ,]+' | Where-Object { $_ }) }
      Write-Host "  DNS geri alindi: $($a.Ad) -> $(if ($a.Statik) { $a.Statik } else { 'otomatik' })"
    } catch { Write-Host "  UYARI: $($a.Ad) DNS'i geri alinamadi: $($_.Exception.Message)" -ForegroundColor Yellow }
  }
  Remove-Item $dnsYedek -Force
}

function DNS-Ayarla {
  $acik = @(Get-NetAdapter | Where-Object Status -eq 'Up')
  if ($acik.Count -eq 0) { throw "Acik ag baglantisi bulunamadi." }
  $liste = foreach ($n in $acik) {
    $k  = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$($n.InterfaceGuid)"
    $k6 = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters\Interfaces\$($n.InterfaceGuid)"
    $statik  = (Get-ItemProperty $k  -ErrorAction SilentlyContinue).NameServer
    $statik6 = (Get-ItemProperty $k6 -ErrorAction SilentlyContinue).NameServer
    $v6Var   = [bool](Get-DnsClientServerAddress -InterfaceAlias $n.Name -AddressFamily IPv6 -ErrorAction SilentlyContinue).ServerAddresses
    [pscustomobject]@{ Ad = $n.Name; Statik = "$statik"; Statik6 = "$statik6"; V6 = $v6Var }
  }
  # Once yedegi diske yaz, sonra degistir (cokme olursa Erisim_Kapat geri alabilsin)
  ConvertTo-Json @($liste) | Out-File $dnsYedek -Encoding utf8
  foreach ($a in $liste) {
    Set-DnsClientServerAddress -InterfaceAlias $a.Ad -ServerAddresses @('127.0.0.1', $yedekDns)
    Write-Host "  DNS ayarlandi: $($a.Ad) -> 127.0.0.1, $yedekDns  (eskisi: $(if ($a.Statik) { $a.Statik } else { 'otomatik' }))"
    # Modem IPv6 DNS veriyorsa sorgular koprunun disina kacmasin
    if ($a.V6) {
      try { Set-DnsClientServerAddress -InterfaceAlias $a.Ad -ServerAddresses @('::1', '2606:4700:4700::1111'); Write-Host "  IPv6 DNS de kopruye yonlendirildi: $($a.Ad)" }
      catch { Write-Host "  UYARI: IPv6 DNS ayarlanamadi: $($_.Exception.Message)" -ForegroundColor Yellow }
    }
  }
}

function Temizle([switch]$Sessiz) {
  Get-Process goodbyedpi -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
  DNS-Geri
  Kopru-Durdur
  ipconfig /flushdns | Out-Null
  if (-not $Sessiz) { Write-Host "GoodbyeDPI ve DNS koprusu kapatildi, DNS ayarlari eski haline dondu." -ForegroundColor Green }
}

if (-not (Yonetici)) { Write-Host "Yonetici olarak calistirilmali. Erisim_Ac.cmd dosyasini kullan." -ForegroundColor Red; Read-Host 'Enter'; return }

# ---------- KAPAT ----------
if ($Kapat) { Temizle; Start-Sleep -Seconds 3; return }

# ---------- AC ----------
foreach ($f in $exe, $kopru) { if (-not (Test-Path $f)) { Write-Host "Dosya bulunamadi: $f" -ForegroundColor Red; Read-Host 'Enter'; return } }

try { Start-Transcript -Path (Join-Path $dir 'erisim_log.txt') -Force | Out-Null } catch {}
try {
  $Host.UI.RawUI.WindowTitle = 'Erisim araci (GoodbyeDPI) - KAPATMA, K ile kapat'
  Write-Host "Eski kalintilar temizleniyor..."
  Temizle -Sessiz

  if (Get-NetUDPEndpoint -LocalAddress 127.0.0.1 -LocalPort 53 -ErrorAction SilentlyContinue) { throw "53 numarali port baska bir program tarafindan kullaniliyor." }

  Write-Host "DNS koprusu aciliyor..."
  Remove-Item $kopruLog -ErrorAction SilentlyContinue
  $kp = Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$kopru`" -Port 53 -Log `"$kopruLog`"" -WindowStyle Hidden -PassThru
  Start-Sleep -Seconds 3
  if ($kp.HasExited) { throw "DNS koprusu baslatilamadi." }
  $test = $null
  try { $test = (Resolve-DnsName $kontrol[0] -Server 127.0.0.1 -DnsOnly -Type A -ErrorAction Stop | Where-Object IPAddress | Select-Object -First 1).IPAddress } catch {}
  if (-not $test) { throw "DNS koprusu cevap vermiyor." }
  Write-Host "  kopru calisiyor ($($kontrol[0]) = $test)"

  Write-Host "DNS ayarlari gecici olarak degistiriliyor..."
  DNS-Ayarla
  ipconfig /flushdns | Out-Null

  Write-Host "GoodbyeDPI aciliyor ($gdpiArgs)..."
  $p = Start-Process -FilePath $exe -ArgumentList $gdpiArgs -WorkingDirectory (Split-Path $exe) -WindowStyle Hidden -PassThru
  Start-Sleep -Seconds 3
  if ($p.HasExited) { throw "GoodbyeDPI baslatilamadi (cikis kodu $($p.ExitCode))." }

  Write-Host "Baglanti kontrol ediliyor..."
  foreach ($s in $kontrol) {
    $kod = & curl.exe -s -o NUL -w '%{http_code}' --max-time 10 "https://$s/" 2>$null
    if ($kod -match '^[1-5]\d\d$') { Write-Host ("  {0,-20} ACILDI" -f $s) -ForegroundColor Green }
    else { Write-Host ("  {0,-20} acilmadi (kod {1})" -f $s, $kod) -ForegroundColor Yellow }
  }

  Write-Host ""
  Write-Host "==============================================" -ForegroundColor Green
  Write-Host "  HAZIR. Discord, Roblox vb. simdi acilabilir."  -ForegroundColor Green
  Write-Host "  Bu pencereyi KAPATMA, kucultebilirsin."        -ForegroundColor Green
  Write-Host "  Isin bitince buraya gelip K tusuna bas."      -ForegroundColor Green
  Write-Host "==============================================" -ForegroundColor Green
  Start-Sleep -Milliseconds 500
  try { $Host.UI.RawUI.FlushInputBuffer() } catch {}
  while ($true) {
    if ($p.HasExited)  { throw "GoodbyeDPI kendiliginden kapandi (cikis kodu $($p.ExitCode))." }
    if ($kp.HasExited) { throw "DNS koprusu kendiliginden kapandi. Ayrintilar: $kopruLog" }
    if ([Console]::KeyAvailable) {
      $k = [Console]::ReadKey($true)
      if ($k.Key -eq 'K') { Write-Host "Kapatiliyor..."; break }
    }
    Start-Sleep -Milliseconds 300
  }
}
catch {
  Write-Host "HATA: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
  Temizle
  try { Stop-Transcript | Out-Null } catch {}
  Write-Host ""
  Write-Host "Pencereyi kapatmak icin bir tusa bas..."
  try { $Host.UI.RawUI.FlushInputBuffer() } catch {}
  [void][Console]::ReadKey($true)
}
