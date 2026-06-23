# Zestawienie SOAR

*SOAR to rozwiązanie w zakresie cyberbezpieczeństwa, które automatyzuje reagowanie na incydenty związane z cyberatakami oraz operacje związane z bezpieczeństwem.*

No dobrze mamy narzędzie, które generuje nam eventy, teraz trzeba te eventy przesłać i odpowiednio obsłużyć. Nasz klaster obsługuje zespół *devops-team*, który zajmuje się utrzymaniem aplikacji, jeśli jest jakiś problem z jej działaniem na produkcji zespół wchodzi do podów - zespół ma otrzymywać eventy z wejścia do każdego poda i potwierdzać je. Cała reszta eventów będzie przekazywana do zespołu *soc-project-team* na dalszą analizę.

## Utworzenie kanałów komunikacji
W większej firmie, kanałami komunikacji są zazwyczaj kolejki na jirze, kanały na slacku lub rozmowa telefoniczna. Na potrzeby tych warsztatów założymy, że głównym kanałem komunikacji w naszej organizacji będzie discord.

### Utworzenie kanałów
Proszę utworzyć na discord serwerze przeznaczonym pod te warsztaty 2 kanały tekstowe:
- *devops-team*
- *soc-project-team*

Następnie należy kliknąć w nazwę serwera (lewy górny róg) -> `Ustawienia serwera` -> w kategorii `APLIKACJE` wybrać `Integracje` -> `Webhooki`

Tworzymy 2 nowe webhooki:
- `Nowy webhook` -> nadajemy mu nazwę `n8n-soc` wybieramy kanał *soc-project-team* -> `Skopiuj adres URL webhooka`
- `Nowy webhook` -> nadajemy mu nazwę `n8n-dev` wybieramy kanał *devops-team*

Klikamy przycisk `Zapisz zmiany` - dół ekranu. Proszę nie zamykać tego menu w discordzie, do momentu skopiowania obu adresów URL webhooka.

## Logowanie do n8n
Należy zarejestrować się do narzędzia n8n [https://app.n8n.cloud/register](https://app.n8n.cloud/register), po rejestracji platforma będzie działać 14 dni. Następnie należy przeklikać się do waszej nowo utworzonej instancji. Wybrać po lewej z zakładki opcję **Overview**.

### Tworzenie Discord webhook
Wybieramy *Build a workflow*, w celu utworzenia nowej automatyzacji. Za pomocą znaku `+` w prawym górnym rogu dodajemy blok -> `Discord` -> `Send a message` i ustawiamy:

Connection Type: `Webhook`

Credential for Discord Webhook: `Set up credential` -> Wklejamy adres webhooka `n8n-soc` -> `Save` -> Zamykamy okno *Credential*

Message:
```
Projekt: **killercoda-n8n**
Time: {{ $json.body.time }}
Priority: {{ $json.body.priority }}

Asset
hostname: {{ $json.body.hostname }}
container: {{ $json.body.output_fields["container.name"] }}

Event: {{ $json.body.output }}

Host: {{ $json.body.hostname }}

Tags:
{{ $json.body.tags }}
```

Zamykamy opcje bloku Discord (x). Wybieramy nowo utworzony blok, zmieniamy jego nazwę na `n8n-soc` i duplikujemy go (`ctrl + d`), klikamy dwukrotnie w nowy blok w celu edycji, w polu `Credential for Discord Webhook` tworzymy nowe credentiale i wklejamy w nie adres webhooka `n8n-dev`, zapisujemy. Zmieniamy nazwę bloku na `n8n-dev`


Dodajemy nowy blok `If`, podłączamy `true` do `n8n-dev`, a `false` do `n8n-soc` w conditions ustawiamy:
```
{{ $json.body.rule }} is equal to
Terminal shell in container
```
Proszę zwrócić uwagę na to co jest wklejane gdzie.

Dodajemy kolejny blok `Webhook`, ustawiamy w nim `HTTP Method` na `POST`, **kopiujemy Webhook Production URL**. Łączymy blok `Webhook` z `If` i jak przedstawia obrazek poniżej, całą resztę bloków która utworzyła się po drodze i ich połączenia można usunąć:
![n8n-obrazek](https://i.imgur.com/R6z1ej9.png)

Na koniec przechodzimy z zakładki **Editor** do zakładki **Executions**, znajduje się ona na środku w górnej części okna i wybieramy **Publish**, znajduje się w prawej górnej części ekranu. 

W tym przypadku n8n będzie pełniło nam rolę *SOAR*. **NIE ZALECAM UŻYWANIA TEJ APLIKACJI DO PRZESYŁANIA WAŻNYCH DANYCH/DOSTĘPU DO PRYWATNYCH ŚRODOWISK** z uwagi na wcześniejsze krytyczne podatności [10.0 w skali CVSS](https://nvd.nist.gov/vuln/detail/CVE-2026-21858) jakie ta aplikacja sprezentowała. Niemniej jednak do zrozumienia przepływu danych jest ona idealna, należy pamiętać że każdy taki scenariusz można napisać samemu w dowolnym języku programowania.

Prezentowany tutaj przykład jest minimalistyczny, ale można by było wykorzystać platformę SOAR do tego, by poddała kwarantannie deployment, który jest aktualnie wdrożony na klastrze, jeśli wykrylibyśmy podejrzane działania, [falco udostępnia własny silnik](https://github.com/falcosecurity/falco-talon) do podejmowania takich akcji. Można by założyć od razu issue na gitlabie jeśli wykrylibyśmy, że jakaś biblioteka w naszym stacku jest podatna. Lub sprawdzili, czy nie ma już taska na taką operację w naszym kanale komunikacji. Jeśli na klastrze wykrylibyśmy plik o sygnaturze malware moglibyśmy od razu przenieść ten plik do kwarantanny.

## Deployment falcosidekick

**Falcosidekick** umożliwia przekazywanie eventów wygenerowanych przez falco do innych endpointów, umożliwia przeglądanie wygenerowanych eventów i nie tylko. W tych warsztatach posłuży nam jednak tylko do przekazywania logów dalej.

W pliku `values.yaml` użyjemy wcześniej skopiowanego webhook URL z n8n (blok Webhook) ma on format: `http://3.91.220.165:5678/webhook/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`. 

Do stworzenia tego pliku proszę użyć zakładkę `Editor` już na platformie killercoda znajduje się ona nad terminalem. Klikamy prawy klawisz pod innymi plikami w tym katalogu i wybieramy opcję `New File`.

```
tty: true #szybsze generowanie alertów przez falco
kubernetes: 
  enabled: true #włączone alerty dla kubernetes audit

falcosidekick:
  enabled: true
  webui:
    enabled: false #nie chcemy wyswietlania strony z logami

  config:
    webhook:
      method: POST
      address: "http://3.91.220.165:5678/webhook/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
      customheaders: "Content-Type: application/json"
      checkcert: false
```

Środowisko w którym jest uruchomione n8n nie posiada odpowiedniego certyfikatu dla domeny więc niezbędne było użycie `checkcert: false`.

Po zapisaniu pliku `values.yaml` przechodzimy do zakładki `Tab1` i wykonujemy komendę:

```
helm upgrade falco falcosecurity/falco -n falco -f values.yaml
```{{exec}}

### Czekamy aż wszystkie pody będą miały STATUS Running:
Zajmie to znowu około ~1m.
```
root@controlplane:~$ kubectl get pods -n falco
NAME                                   READY   STATUS    RESTARTS   AGE
falco-falcosidekick-6775f9d56f-67cth   1/1     Running   0          76s
falco-falcosidekick-6775f9d56f-mm6pq   1/1     Running   0          76s
falco-mbqs4                            2/2     Running   0          46s
falco-sw96x                            2/2     Running   0          70s
```

możemy to sprawdzić przy użyciu komendy:
```
kubectl get pods -n falco
```{{exec}}

### Przetestowanie reguł dla zespołu *soc-project-team*

```
cat /etc/shadow
```{{exec}}

Powinno przyjść powiadomienie na odpowiedni kanał.


### Przetestowanie reguł dla zespołu *devops-team*

```
kubectl exec -it $(kubectl get pods --selector=app=nginx -o name) -- /bin/bash
```{{exec}}

a później:

```
exit
```{{exec}}

Można przejść dalej, jeśli każde z powiadomień trafiło na inny kanał.