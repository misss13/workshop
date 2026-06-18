# Zestawienie SOAR

**SOAR** to rozwiązanie w zakresie cyberbezpieczeństwa, które automatyzuje reagowanie na incydenty związane z cyberatakami oraz operacje związane z bezpieczeństwem.

No dobrze mamy narzędzie, które generuje nam eventy, teraz trzeba te eventy przesłać i odpowiednio obsłużyć. Nasz klaster obsługuje zespół; *app-team*, który zajmuje się pisaniem aplikacji, jeśli jest jakiś problem z działaniem aplikacji na produkcji zespół wchodzi do podów - zespół ma otrzymywać eventy z wejścia do każdego poda i potwierdzać je. Cała reszta eventów będzie przekazywana do zespołu *soc-project-team* na dalszą analizę.

## Utworzenie kanałów komunikacji
W większej firmie, kanałami komunikacji są zazwyczaj kolejki na jirze, kanały na slacku. Na potrzeby tych warsztatów założymy że głównym kanałem komunikacji w naszej organizacji będzie discord.

### Utworzenie kanałów
Proszę utworzyć na discord serwerze przeznaczonym pod te warsztaty 2 kanały tekstowe:
- *application-team*
- *soc-project-team*

Następnie należy kliknąć w nazwę serwera (lewy górny róg) -> `Ustawienia serwera` -> w kategorii `APLIKACJE` wybrać `Integracje` -> `Webhooki`

Tworzymy 2 nowe webhooki:
- `Nowy webhook` -> nadajemy mu nazwę `n8n-soc` wybieramy kanał *soc-project-team* -> `Skopiuj adres URL webhooka`
- `Nowy webhook` -> nadajemy mu nazwę `n8n-app` wybieramy kanał *application-team*

Proszę nie zamykać tego menu w discordzie, do momentu skopiowania obu adresów URL webhooka.

## Logowanie do n8n
Należy zalogować się do narzędzia n8n dostępnego pod adresem [redacted], oraz wybrać konto [redacted]. 

### Tworzenie discord webhook
Wybieramy *Build a workflow*, za pomocą znaku `+` w prawym górnym rogu dodajemy blok -> `Discord` -> `Send a message` i ustawiamy:

Connection Type: `Webhook`

Credential for Discord Webhook: `Create a new credential` -> Wklejamy adres webhooka `n8n-soc`

Message:
```
Projekt: **killercoda-n8n**
Time: {{ $json.body.time }}
Priority: {{ $json.body.priority }}
Asset
hostname: {{ $json.body.hostname }}
container: {{ $json.body.output_fields["container.name"] }}
Tags:
{{ $json.body.tags }}
```

Input Method: `Enter Fields`

Description: `{{ $json.body.output }}`

Color: 
```
{{
  $json.body.priority === 'Critical'
    ? parseInt('EF4444', 16)
    : $json.body.priority === 'Warning'
      ? parseInt('F59E0B', 16)
      : parseInt('22C55E', 16)
}}
```

Timestamp: `{{ $json.body.time }}`

Zamykamy opcje (x). Wybieramy nowo utworzony blok, zmieniamy jego nazwę na n8n-soc i duplikujemy go (`ctrl + d`), w polu `Credential for Discord Webhook` tworzymy nowe credentiale i wklejamy w nie adres webhooka `n8n-app`. Zmieniamy nazwę bloku na `n8n-app`


Dodajemy nowy blok `If`, podłączamy `true` do `n8n-app`, a false do `n8n-soc` w conditions wklejamy:
```
{{ $json.body.rule }} is equal to
Terminal shell in container
```

Dodajemy kolejny blok `Webhook`, zostawiamy domyślne ustawienia, **kopiujemy Webhook TEST URL**. Na koniec łączymy blok `Webhook` z `If` i otrzymujemy:
![n8n-obrazek](https://i.imgur.com/mG9gQ9K.png)

W tym przypadku n8n będzie pełniło nam rolę minimalistycznego SOAR. **NIE ZALECAM UŻYWANIA TEJ APLIKACJI DO PRZESYŁANIA WAŻNYCH DANYCH/DOSTĘPU DO PRYTWANYCH ŚRODOWISK** z uwagi na wcześniejsze krytyczne podatności [10.0 w skali CVSS](https://nvd.nist.gov/vuln/detail/CVE-2026-21858) jakie ta aplikacja sprezentowała. Niemniej jednak do zrozumienia przepływu danych jest ona idealna, należy pamiętać że każdy taki scenariusz można napisać samemu w dowolnym języku programowania.

Prezentowany tutaj przykład jest minimalistyczny, ale możnaby było wykorzystać platformę SOAR do tego by poddała kwarantannie deployment, który jest aktualnie wdrożony na klastrze, jeśli wykrylibyśmy podejrzane działania, [falco udostępnia własny silnik](https://github.com/falcosecurity/falco-talon) do podejmowania takich akcji. Możnaby założyć od razu issue na gitlabie jeśli wykrylibyśmy, że jakaś biblioteka w naszym stacku jest podatna. Lub sprawdzili czy nie ma już taska na taką operację w naszym kanale komunikacji.

## Deployment falcosidekick

**Falcosidekick** umożliwia przekazywanie eventów wygenerowanych przez falco do innych endpointów, umożliwia przeglądanie wygenerówanych eventów i nie tylko. W tych warsztatach posłuży nam jednak tylko do przekazywania logów dalej.

W pliku `values.yaml` użyjemy wcześniej skopiowanego webhook URL z n8n ma on format: `http://3.91.220.165:5678/webhook-test/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`. 

Do stworzenia tego pliku proszę użyć zakładkę `Editor` znajduje się ona nad konsolą. 

```
tty: true #szybsze generowanie alertów przez falco
kubernetes: 
  enabled: true #wlaczone alerty dla kubernetes audit

falcosidekick:
  enabled: true
  webui:
    enabled: false #nie chcemy wyswietlania strony z logami

  config:
    webhook:
      method: POST
      address: "http://3.91.220.165:5678/webhook-test/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
      customheaders: "Content-Type: application/json"
      checkcert: false
```

Środowisko w którym jest uruchomione n8n nie posiada odpowiedniego certyfikatu dla domeny więc niezbędne było użycie `checkcert: false`.

Po zapisaniu pliky `values.yaml` przechodzimy do zakładki `Tab1` i wykonujemy komendę:

```
helm upgrade falco falcosecurity/falco -n falco -f values.yaml
```{{exec}}