# Üçüncü Taraf Bileşenler

Bu depo, aşağıda listelenen üçüncü taraf yazılımların derlenmiş (ikili) dosyalarını içermektedir. Bu dosyalar **hiçbir değişiklik yapılmadan** dağıtılmaktadır. Her bileşen kendi lisansına tabidir; bu projenin [MIT lisansı](LICENSE) yalnızca depodaki betikleri (`*.cmd`, `*.ps1`) kapsar.

Bu proje, aşağıdaki projelerin geliştiricileri tarafından onaylanmamış veya desteklenmemiştir; bu projelerle resmi bir bağlantısı yoktur.

---

## GoodbyeDPI

| | |
|---|---|
| **Sürüm** | 0.2.3rc3 |
| **Dosyalar** | `x86/goodbyedpi.exe`, `x86_64/goodbyedpi.exe` |
| **Telif hakkı** | ValdikSS ve katkıda bulunanlar |
| **Lisans** | Apache License 2.0 — [`licenses/third-party/LICENSE-goodbyedpi.txt`](licenses/third-party/LICENSE-goodbyedpi.txt) |
| **Kaynak kodu** | https://github.com/ValdikSS/GoodbyeDPI |
| **Sürümler** | https://github.com/ValdikSS/GoodbyeDPI/releases |

GoodbyeDPI aşağıdaki bileşenleri içermektedir:

| Bileşen | Telif hakkı | Lisans |
|---|---|---|
| getline | The NetBSD Foundation, Inc. (2011) | BSD 2 maddeli lisans — [`LICENSE-getline.txt`](licenses/third-party/LICENSE-getline.txt) |
| uthash | Troy D. Hanson (2005-2014) | BSD lisansı — [`LICENSE-uthash.txt`](licenses/third-party/LICENSE-uthash.txt) |

## WinDivert

| | |
|---|---|
| **Sürüm** | 2.2 |
| **Dosyalar** | `x86/WinDivert.dll`, `x86/WinDivert32.sys`, `x86/WinDivert64.sys`, `x86_64/WinDivert.dll`, `x86_64/WinDivert64.sys` |
| **Telif hakkı** | basil ([basil00](https://github.com/basil00)) |
| **Lisans** | GNU Lesser General Public License v3 veya GNU General Public License v2 (kullanıcının tercihine bağlı) — [`licenses/third-party/LICENSE-windivert.txt`](licenses/third-party/LICENSE-windivert.txt) |
| **Kaynak kodu** | https://github.com/basil00/WinDivert |
| **Sürümler** | https://github.com/basil00/WinDivert/releases |

WinDivert'in bu depoda dağıtılan sürümüne (2.2) ait kaynak kodu, yukarıdaki bağlantılarda yer alan resmi WinDivert deposundan edinilebilir. Kaynak koduna erişimde sorun yaşanması hâlinde depodaki [Issues](../../issues) bölümü üzerinden talepte bulunabilirsiniz.

---

## Dosyaların Kaynağı

İkili dosyalar, GoodbyeDPI 0.2.3rc3 sürümüne dayanan ve Türkiye için hazırlanmış `goodbyedpi-0.2.3rc3-turkey` paketinden alınmıştır. Bu paketin içerdiği yapılandırma betikleri (`service_install_*.cmd`, `turkey_dnsredir*.cmd`) bu depoya **dahil edilmemiştir**.

Dosyaların bütünlüğünü doğrulamak için [README](README.md#güvenlik-ve-doğrulama) dosyasındaki SHA-256 özetlerini kullanabilir veya dosyaları GoodbyeDPI'ın resmi sürümlerinden kendiniz indirdiğiniz dosyalarla değiştirebilirsiniz.
