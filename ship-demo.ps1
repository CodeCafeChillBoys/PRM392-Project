# ship-demo.ps1 - Gia lap shipper LAI XE DOC THEO DUONG THAT toi nha khach (demo tracking).
#
# - Xe di theo TUYEN DUONG THAT (Goong Direction, vehicle=bike - GIONG app ve route).
# - Diem xuat phat = vi tri shipper HIEN TAI (khong nhay ve kho, tru khi -FromStore).
# - Tu chon dung don STAFF DANG "Xem & Chay" (tracking moi nhat) neu khong truyen -OrderId.
#
# CACH CHAY (de nhat - tu nhan don dang giao):
#     powershell -ExecutionPolicy Bypass -File .\ship-demo.ps1
#
# TUY CHON:
#     -OrderId <ma>   : ep chon 1 don (ma ngan nhu tren app hoac GUID). Phai la don STAFF dang chay!
#     -FromStore      : bat dau tu KHO thay vi vi tri hien tai (khi muon chay lai tu dau)
#     -DelaySec <s>   : giay moi diem (mac dinh 1.2)
#     -SubPerStep <n> : so diem chen giua moi doan cho muot (mac dinh 2)

param(
  [string]$OrderId = "",
  [switch]$FromStore,
  [double]$DelaySec = 1.2,
  [int]$SubPerStep = 2
)

$adb = "C:\Users\Kangnahyun\AppData\Local\Android\Sdk\platform-tools\adb.exe"
$goongKey = "VSKJ58vQTZLz7gBwKSxGsqKrEO8vElEkHXwZ5yyc"
$beBase = "http://localhost:5173"
$ic = [System.Globalization.CultureInfo]::InvariantCulture
$storeLat = 10.841122; $storeLng = 106.809935

if (-not (Test-Path $adb)) { Write-Host "Khong tim thay adb: $adb"; exit 1 }
function Fmt([double]$v) { return $v.ToString("F6", $ic) }

# Lay vi tri tracking hien tai cua 1 don (null neu chua co)
function Get-Track($id) {
  try { return Invoke-RestMethod "$beBase/api/tracking/order/$id" -TimeoutSec 5 } catch { return $null }
}

# ---- 1) Chon DON --------------------------------------------------------------
$order = $null; $track = $null
try { $orders = Invoke-RestMethod "$beBase/api/Orders" -TimeoutSec 8 }
catch { Write-Host "!! Khong goi duoc BE ($beBase). BE da chay chua?"; exit 1 }

if ($OrderId -ne "") {
  $order = $orders | Where-Object { "$($_.id)" -like "$OrderId*" } | Select-Object -First 1
  if (-not $order) { Write-Host "!! Khong thay don '$OrderId'."; exit 1 }
  $track = Get-Track $order.id
  Write-Host "LUU Y: hay chac -OrderId nay dung don STAFF dang 'Xem & Chay' (khach dang theo doi)."
} else {
  # Tu chon don Shipped co tracking MOI NHAT = don shipper dang thuc su chay
  $bestTime = [DateTime]::MinValue
  foreach ($o in ($orders | Where-Object { $_.status -eq "Shipped" })) {
    $t = Get-Track $o.id
    if ($t -and $t.updatedAt) {
      $ut = [DateTime]$t.updatedAt
      if ($ut -gt $bestTime) { $bestTime = $ut; $order = $o; $track = $t }
    }
  }
  if (-not $order) { Write-Host "!! Khong don nao co vi tri shipper. STAFF da bam 'Xem & Chay' chua?"; exit 1 }
  Write-Host ("(Tu chon) Don dang giao: #{0}" -f "$($order.id)".Substring(0, 8))
}

$shortId = "$($order.id)".Substring(0, 8)
$addr = $order.shippingAddress

# ---- 2) Toa do NHA KHACH (dich) = geocode dia chi (giong app ve pin) ----------
$hLat = 0.0; $hLng = 0.0
try {
  $g = Invoke-RestMethod "https://rsapi.goong.io/Geocode?api_key=$goongKey&address=$([uri]::EscapeDataString($addr))" -TimeoutSec 10
  if ($g.results.Count -gt 0) { $hLat = [double]$g.results[0].geometry.location.lat; $hLng = [double]$g.results[0].geometry.location.lng }
} catch {}
if ($hLat -eq 0 -and $order.latitude) { $hLat = [double]$order.latitude; $hLng = [double]$order.longitude }
Write-Host ("Nha khach #{0}: {1}  ({2} , {3})" -f $shortId, $addr, (Fmt $hLat), (Fmt $hLng))

# ---- 3) Diem XUAT PHAT = vi tri shipper hien tai (KHONG nhay ve kho) ----------
$sLat = $storeLat; $sLng = $storeLng; $startSrc = "kho"
if (-not $FromStore -and $track -and $track.lat -and $track.lng) {
  $sLat = [double]$track.lat; $sLng = [double]$track.lng; $startSrc = "vi tri shipper hien tai"
} elseif ($FromStore) {
  $startSrc = "kho (-FromStore)"
}
Write-Host ("Xuat phat: {0}  ({1} , {2})" -f $startSrc, (Fmt $sLat), (Fmt $sLng))
if ((-not $FromStore) -and ([Math]::Abs($sLat - $hLat) -lt 0.005) -and ([Math]::Abs($sLng - $hLng) -lt 0.005)) {
  Write-Host "   (Shipper dang sat nha -> xe se it di chuyen. Muon chay tu kho: them -FromStore)"
}

# ---- 4) TUYEN DUONG THAT (Goong Direction, steps) -> danh sach diem -----------
$route = @()
try {
  $u = "https://rsapi.goong.io/Direction?origin={0},{1}&destination={2},{3}&vehicle=bike&api_key={4}" -f (Fmt $sLat), (Fmt $sLng), (Fmt $hLat), (Fmt $hLng), $goongKey
  $d = Invoke-RestMethod $u -TimeoutSec 12
  if ($d.routes.Count -gt 0) {
    $steps = $d.routes[0].legs[0].steps
    $wp = @()
    foreach ($s in $steps) { $wp += [PSCustomObject]@{ Lat = [double]$s.start_location.lat; Lng = [double]$s.start_location.lng } }
    $last = $steps[$steps.Count - 1]
    $wp += [PSCustomObject]@{ Lat = [double]$last.end_location.lat; Lng = [double]$last.end_location.lng }
    for ($j = 0; $j -lt $wp.Count - 1; $j++) {
      $a = $wp[$j]; $b = $wp[$j + 1]
      for ($m = 0; $m -lt $SubPerStep; $m++) {
        $f = [double]$m / $SubPerStep
        $route += [PSCustomObject]@{ Lat = ($a.Lat + ($b.Lat - $a.Lat) * $f); Lng = ($a.Lng + ($b.Lng - $a.Lng) * $f) }
      }
    }
    $route += $wp[$wp.Count - 1]
    Write-Host ("Tuyen duong that: {0} step -> {1} diem" -f $steps.Count, $route.Count)
  }
} catch { Write-Host "!! Direction loi: $($_.Exception.Message)" }

if ($route.Count -lt 2) {
  Write-Host "!! Khong lay duoc tuyen duong -> tam di duong thang."
  $route = @()
  for ($k = 1; $k -le 15; $k++) { $f = [double]$k / 15; $route += [PSCustomObject]@{ Lat = ($sLat + ($hLat - $sLat) * $f); Lng = ($sLng + ($hLng - $sLng) * $f) } }
}

# ---- 5) Cho xe bo DOC THEO DUONG ---------------------------------------------
$emus = @()
foreach ($line in (& $adb devices)) { if ($line -match "^(emulator-\d+)\s+device") { $emus += $matches[1] } }
if ($emus.Count -eq 0) { Write-Host "Khong co may ao nao dang chay!"; exit 1 }
Write-Host ("May ao: {0} | {1} diem | ~{2}s" -f ($emus -join ", "), $route.Count, [int]($route.Count * $DelaySec))
Write-Host "Xe lan banh doc theo duong... (Ctrl+C de dung)"

$i = 0
foreach ($p in $route) {
  $i++
  $latS = Fmt ([double]$p.Lat); $lngS = Fmt ([double]$p.Lng)
  foreach ($e in $emus) { & $adb -s $e emu geo fix $lngS $latS | Out-Null }
  if ($i % 3 -eq 0 -or $i -eq $route.Count) { Write-Host ("  diem {0}/{1} -> {2} , {3}" -f $i, $route.Count, $latS, $lngS) }
  Start-Sleep -Seconds $DelaySec
}
Write-Host ("XE DA TOI NHA KHACH #{0} - {1}" -f $shortId, $addr)
