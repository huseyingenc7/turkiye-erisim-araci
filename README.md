# Türkiye Erişim Aracı

Türkiye'de erişim engeli bulunan sitelere ve uygulamalara (Discord, Roblox, Roblox Studio vb.) Windows üzerinden erişim sağlamak için hazırlanmış, kurulum gerektirmeyen bir araçtır.

Araç, [GoodbyeDPI](https://github.com/ValdikSS/GoodbyeDPI)'ı **Windows hizmeti olarak kurmadan** çalıştırır ve DNS sorgularını şifreli DNS (DNS-over-HTTPS) üzerinden iletir. Bilgisayar açılışında hiçbir bileşen otomatik olarak başlamaz; araç yalnızca kullanıcı tarafından çalıştırıldığında etkindir ve kapatıldığında sistem ayarları önceki hâline döndürülür.

> **Not:** Araç Türk Telekom altyapısında test edilmiştir. Diğer internet servis sağlayıcılarında (Turkcell Superonline, Vodafone, TurkNet vb.) çalışması garanti edilmez. Farklı bir sağlayıcıda denediyseniz sonucu [Issues](../../issues) bölümünden bildirmeniz diğer kullanıcılara yardımcı olacaktır.

---

## İçindekiler

- [Gereksinimler](#gereksinimler)
- [Kurulum](#kurulum)
- [Kullanım](#kullanım)
- [Nasıl Çalışır](#nasıl-çalışır)
- [Test Sonuçları](#test-sonuçları)
- [Bilinen Sınırlamalar](#bilinen-sınırlamalar)
- [Sorun Giderme](#sorun-giderme)
- [Güvenlik ve Doğrulama](#güvenlik-ve-doğrulama)
- [Dosya Yapısı](#dosya-yapısı)
- [Lisans](#lisans)
- [Sorumluluk Reddi](#sorumluluk-reddi)

---

## Gereksinimler

- Windows 10 veya Windows 11 (64 bit veya 32 bit)
- Yönetici (administrator) yetkisi
- Ek bir program kurulumu gerekmez; Windows ile birlikte gelen PowerShell kullanılır.

## Kurulum

1. Bu sayfanın sağ tarafındaki **Releases** bölümünden en güncel `.zip` dosyasını indirin.
   (Alternatif olarak yeşil **Code** düğmesinden **Download ZIP** seçeneğini kullanabilirsiniz.)
2. ZIP dosyasını bir klasöre çıkarın (örneğin Masaüstü).
   **Dosyaları ZIP arşivinin içinden çalıştırmayın.**

Herhangi bir kurulum adımı yoktur.

## Kullanım

1. Erişmek istediğiniz uygulama (Discord, Roblox Studio vb.) açıksa kapatın.
2. `Erisim_Ac.cmd` dosyasına çift tıklayın ve yönetici izni istendiğinde **Evet**'i seçin.
3. Açılan pencerede yeşil **HAZIR** ifadesi görüntülendiğinde uygulamayı veya siteyi açın.
   Pencereyi kapatmayın; simge durumuna küçültebilirsiniz.
4. İşiniz bittiğinde pencereye dönün ve **K** tuşuna basın. Tüm değişiklikler geri alınır.

Pencere **K** tuşuna basılmadan kapatılırsa `Erisim_Kapat.cmd` dosyasını çalıştırarak ayarları önceki hâline döndürebilirsiniz. Bu durumda internet bağlantınız çalışmaya devam eder. Ayrıca bir sonraki `Erisim_Ac.cmd` çalıştırmasında kalan ayarlar otomatik olarak temizlenir.

## Nasıl Çalışır

Türkiye'deki erişim engelleri genellikle iki aşamada uygulanır:

| Engel | Açıklama | Aracın çözümü |
|---|---|---|
| **DNS engeli** | Sitenin alan adı IP adresine çözümlenemez. Türk Telekom, standart DNS sorgularını (53, 1253, 5353 ve 443 numaralı UDP portları) farklı DNS sunucularına gönderilse bile engellemektedir. | `dns_kopru.ps1`, bilgisayar üzerinde yerel bir DNS köprüsü (`127.0.0.1:53`) açar ve tüm sorguları şifreli DNS (Cloudflare, yedek olarak Google) üzerinden iletir. |
| **DPI engeli** | Alan adı çözümlense dahi bağlantı, TLS el sıkışmasındaki SNI bilgisi incelenerek kesilir. | GoodbyeDPI `-5 --set-ttl 5` parametreleriyle çalıştırılır. |

Araç çalıştırıldığında sırasıyla şu işlemleri gerçekleştirir:

1. Önceki çalıştırmalardan kalan ayarları temizler.
2. Yerel DNS köprüsünü başlatır ve çalıştığını doğrular.
3. Etkin ağ bağdaştırıcısının mevcut DNS ayarlarını `dns_yedek.json` dosyasına kaydeder.
4. DNS ayarlarını geçici olarak `127.0.0.1` (köprü) ve yedek olarak `1.1.1.1` şeklinde değiştirir. Bağdaştırıcıda IPv6 DNS tanımlıysa bu da köprüye yönlendirilir.
5. GoodbyeDPI'ı hizmet olarak kurmadan başlatır.
6. Örnek sitelere bağlantıyı test eder ve sonucu gösterir.

Kapatma sırasında GoodbyeDPI ve DNS köprüsü sonlandırılır, DNS ayarları kaydedilen yedekten geri yüklenir.

Araç **hosts dosyasını değiştirmez**, **Windows hizmeti oluşturmaz** ve **kalıcı bir sistem değişikliği yapmaz**. DNS köprüsünün beklenmedik şekilde kapanması durumunda Windows yedek DNS sunucusunu (`1.1.1.1`) kullanır; bu nedenle genel internet erişimi kesilmez.

## Test Sonuçları

Türk Telekom bağlantısında, araç etkinken yapılan testlerin sonuçları:

| Hizmet | Durum |
|---|---|
| Discord (web sitesi, sohbet bağlantısı, resim sunucuları) | Erişilebilir |
| Roblox ve Roblox Studio | Erişilebilir |
| Wattpad, Imgur, Pixiv, archive.org | Erişilebilir |
| Discord sesli sohbet | Test edilmedi |

Türk Telekom üzerinde denenen GoodbyeDPI parametrelerinden yalnızca `-5`, `-5 --set-ttl 5` ve `-5 --set-ttl 3` başarılı olmuştur. `-9`, `--wrong-chksum`, `--wrong-seq` ve yalnızca parçalama (`--frag-by-sni`, `--native-frag`) içeren yapılandırmalar başarısız olmuştur.

## Bilinen Sınırlamalar

- Araç yalnızca DNS ve DPI tabanlı engelleri aşar. IP adresi düzeyinde engellenen hizmetler için VPN gereklidir.
- Araç çalıştığı süre boyunca bilgisayardaki tüm DNS trafiği şifreli DNS üzerinden iletilir.
- Yalnızca Windows'ta çalışır.
- 53 numaralı UDP portunu kullanan başka bir yazılım (DNS sunucusu, bazı VPN istemcileri vb.) çalışıyorsa DNS köprüsü başlatılamaz.

## Sorun Giderme

| Belirti | Olası neden ve çözüm |
|---|---|
| Pencere açılıp hemen kapanıyor | Yönetici izni verilmemiş olabilir. `Erisim_Ac.cmd` dosyasını yeniden çalıştırıp izni onaylayın. |
| "53 numaralı port başka bir program tarafından kullanılıyor" | DNS veya VPN yazılımlarını kapatıp tekrar deneyin. |
| "GoodbyeDPI başlatılamadı" | Antivirüs yazılımı WinDivert sürücüsünü engellemiş olabilir. Ayrıntılar için [Güvenlik ve Doğrulama](#güvenlik-ve-doğrulama) bölümüne bakın. |
| HAZIR yazısı görünüyor ancak site açılmıyor | Tarayıcıyı veya uygulamayı tamamen kapatıp yeniden açın. Sağlayıcınız farklı bir engelleme yöntemi kullanıyor olabilir. |
| Araç kapandıktan sonra internet çalışmıyor | `Erisim_Kapat.cmd` dosyasını çalıştırın. |

Hata ayrıntıları araç klasöründeki `erisim_log.txt` ve `kopru_log.txt` dosyalarına kaydedilir. Sorun bildirirken bu dosyaların içeriğini ve internet servis sağlayıcınızı belirtmeniz önerilir.

> **Uyarı:** GoodbyeDPI'ın bazı paketlerinde bulunan `service_install_...` betiklerini kullanmayınız. Bu betikler GoodbyeDPI'ı otomatik başlayan bir hizmet olarak kurar ve DNS trafiğini Yandex DNS'e (1253 numaralı port) yönlendirir. Türk Telekom bu portu engellediği için bu yapılandırma tüm internet erişimini kesebilmektedir.

## Güvenlik ve Doğrulama

GoodbyeDPI, ağ paketlerine müdahale etmek için [WinDivert](https://github.com/basil00/WinDivert) çekirdek sürücüsünü kullanır. Bu nedenle bazı antivirüs yazılımları dosyaları "potansiyel olarak istenmeyen yazılım" olarak işaretleyebilir. Bu durum aracın çalışma biçiminden kaynaklanmaktadır.

Yönetici yetkisiyle çalışan bir aracı kullanmadan önce içeriğini incelemeniz önerilir:

- `Erisim_Ac.cmd`, `Erisim_Kapat.cmd`, `erisim_ac.ps1` ve `dns_kopru.ps1` düz metin dosyalarıdır; herhangi bir metin düzenleyiciyle incelenebilir.
- Araç, yalnızca Cloudflare (`cloudflare-dns.com`) ve Google (`dns.google`) şifreli DNS sunucularıyla iletişim kurar.
- Paketteki ikili dosyalar GoodbyeDPI 0.2.3rc3 sürümüne aittir. Dosyaları [GoodbyeDPI'ın resmi sürümleriyle](https://github.com/ValdikSS/GoodbyeDPI/releases) karşılaştırabilir veya kendiniz indirdiğiniz dosyalarla değiştirebilirsiniz.

SHA-256 özetleri:

| Dosya | SHA-256 |
|---|---|
| `x86/goodbyedpi.exe` | `66e202c9fce9e769e2bc791b7fd6f56f21eab59f607f4ed0724e0c68c430dd1f` |
| `x86/WinDivert.dll` | `625ffdd95bfabff32d0e8a95beabcd303c01c8bba73b90402d4e84d6e15dd8e5` |
| `x86/WinDivert32.sys` | `29ca5ceb59c9c6993a349e82b1fd46078e6f8a302764153ab84fa22e382fcdca` |
| `x86/WinDivert64.sys` | `e69b5ba3f0cd6cfb2983e442636e7f0b342b61b15264b0328317d4559c82cf50` |
| `x86_64/goodbyedpi.exe` | `8d412b094bb9c137ff25ba9a794d1122ecc84bb776debff6c249723a13cc31cd` |
| `x86_64/WinDivert.dll` | `6110bfa44667405179c3e15e12af1b62037e447ed59b054b19042032995e6c7e` |
| `x86_64/WinDivert64.sys` | `e69b5ba3f0cd6cfb2983e442636e7f0b342b61b15264b0328317d4559c82cf50` |

PowerShell ile doğrulama:

```powershell
Get-FileHash .\x86_64\goodbyedpi.exe -Algorithm SHA256
```

## Dosya Yapısı

```
turkiye-erisim-araci/
├── Erisim_Ac.cmd        Aracı başlatır (yönetici izni ister)
├── Erisim_Kapat.cmd     Aracı kapatır ve ayarları geri yükler
├── erisim_ac.ps1        Ana betik
├── dns_kopru.ps1        Şifreli DNS köprüsü
├── x86/                 GoodbyeDPI ve WinDivert (32 bit)
├── x86_64/              GoodbyeDPI ve WinDivert (64 bit)
└── licenses/            Lisans metinleri
```

## Lisans

Bu depodaki betikler (`*.cmd`, `*.ps1`) [MIT Lisansı](LICENSE) ile lisanslanmıştır.

Pakete dahil edilen üçüncü taraf yazılımlar kendi lisanslarına tabidir:

| Yazılım | Lisans |
|---|---|
| [GoodbyeDPI](https://github.com/ValdikSS/GoodbyeDPI) | Apache License 2.0 |
| [WinDivert](https://github.com/basil00/WinDivert) | LGPL v3 / GPL v2 |
| getline, uthash | İlgili lisans metinleri |

Lisans metinleri [`licenses/third-party`](licenses/third-party) klasöründe yer almaktadır.

## Sorumluluk Reddi

Bu araç, bilgiye erişim amacıyla ve olduğu gibi (as is) sunulmaktadır; herhangi bir garanti verilmemektedir. Aracın kullanımından doğabilecek her türlü sonuç ve yürürlükteki mevzuata uygunluk kullanıcının sorumluluğundadır.
