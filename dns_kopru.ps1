# Yerel DNS koprusu: 127.0.0.1:<Port> uzerinden gelen DNS sorgularini
# sifreli DNS'e (DNS-over-HTTPS, Cloudflare / Google) iletir ve cevabi geri yollar.
# Hicbir ayari degistirmez; sadece dinler. Kapatmak icin islemi sonlandirmak yeterli.
param([int]$Port = 53, [string]$Log = '')

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Add-Type -AssemblyName System.Net.Http

$sunucular = @('https://cloudflare-dns.com/dns-query', 'https://dns.google/dns-query')
$http = [Net.Http.HttpClient]::new()
$http.Timeout = [TimeSpan]::FromSeconds(5)

function Yaz($s) { if ($Log) { try { "$(Get-Date -Format HH:mm:ss) $s" | Out-File $Log -Append -Encoding utf8 } catch {} } }

function Soket($ip) {
  $s = [Net.Sockets.UdpClient]::new([Net.IPEndPoint]::new($ip, $Port))
  # Windows'ta cevap gonderilemeyen istemci yuzunden soketin bozulmasini engelle (SIO_UDP_CONNRESET)
  try { [void]$s.Client.IOControl(-1744830452, [byte[]](0,0,0,0), $null) } catch {}
  return $s
}
$soketler = @(Soket ([Net.IPAddress]::Loopback))
try { $soketler += Soket ([Net.IPAddress]::IPv6Loopback); Yaz "kopru basladi 127.0.0.1:$Port ve [::1]:$Port" }
catch { Yaz "kopru basladi 127.0.0.1:$Port (IPv6 yok)" }

# Bekleyen istekler: her biri { Task, Ep, Q, Sira, Soket }
$bekleyen = New-Object System.Collections.ArrayList
$say = 0; $hata = 0

function Gonder($q, $sira) {
  $c = [Net.Http.ByteArrayContent]::new($q)
  $c.Headers.ContentType = [Net.Http.Headers.MediaTypeHeaderValue]::new('application/dns-message')
  return $http.PostAsync($sunucular[$sira], $c)
}

while ($true) {
  $isVar = $false

  foreach ($udp in $soketler) {
    while ($udp.Available -gt 0) {
      $isVar = $true
      $ep = [Net.IPEndPoint]::new([Net.IPAddress]::Any, 0)
      try { $q = $udp.Receive([ref]$ep) } catch { continue }
      if ($q.Length -lt 12) { continue }
      [void]$bekleyen.Add([pscustomobject]@{ Task = (Gonder $q 0); Ep = $ep; Q = $q; Sira = 0; Soket = $udp })
      $say++
    }
  }

  for ($i = $bekleyen.Count - 1; $i -ge 0; $i--) {
    $b = $bekleyen[$i]
    if (-not $b.Task.IsCompleted) { continue }
    $isVar = $true
    $cevap = $null
    try {
      if (-not $b.Task.IsFaulted -and -not $b.Task.IsCanceled -and $b.Task.Result.IsSuccessStatusCode) {
        $cevap = $b.Task.Result.Content.ReadAsByteArrayAsync().Result
      }
    } catch {}
    if ($cevap -and $cevap.Length -ge 12) {
      try { [void]$b.Soket.Send($cevap, $cevap.Length, $b.Ep) } catch {}
      $bekleyen.RemoveAt($i)
    }
    elseif ($b.Sira -lt $sunucular.Count - 1) {
      # ilk sunucu olmadi, yedegi dene
      $b.Sira++; $b.Task = Gonder $b.Q $b.Sira
    }
    else {
      $hata++; Yaz "cevap alinamadi (toplam hata: $hata)"
      $bekleyen.RemoveAt($i)
    }
  }

  if (-not $isVar) { Start-Sleep -Milliseconds 5 }
  if (($say -gt 0) -and ($say % 500 -eq 0)) { Yaz "$say sorgu iletildi"; $say++ }
}
