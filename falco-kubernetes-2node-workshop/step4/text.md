# Dodanie nowej reguły

W ramach monitorowania działań na systemie napiszemy własną regułę do monitorowania pliku `authorized_keys`. Plik ten znajduje się w katalogu domowym użytkownika w ścieżce `~/.ssh/authorized_keys` i zawiera klucze publiczne użytkowników, którzy mogą zalogować się na to konto. Dodając do niego wpis z naszym kluczem publicznym, tworzymy sobie dostęp do tego hosta, no pod warunkiem, że przepływy sieciowe nam pozwalają, ale zakładamy że port 22/tcp jest otwarty do internetu. 

Czyli ewentualne zmiany tego pliku mogą powodować dodanie komuś uprawnień do logowania się na konto użytkownika na systemie. Mogą być one spowodowane dostaniem się do systemu osoby niepowołanej a ta chcąc sobie wyrobić stały dostęp do serwera doda sobie swój klucz.

## Budowa reguły

Nasza reguła będzie się nazywać `Ssh keys added to authorized_keys`. Natomiast opis naszej reguły znajduje się poniżej:

```
After gaining access, attackers can modify the authorized_keys file to maintain persistence on a victim host. Where authorized_keys files are modified via cloud APIs or command line interfaces, an adversary may achieve privilege escalation on the target virtual machine if they add a key to a higher-privileged user. This rules aims at detecting any modification to the authorized_keys file, that is usually located under the .ssh directory in any users home directory.
```

Warunki wywołania nowej reguły:
- ktoś musi otworzyć plik do pisania - `open_write`
- oraz ((plik musi być w ścieżce która zawiera /.ssh/ i ścieżka absolutna musi pasować do regexu '/home/*/.ssh/*') lub nazwa ścieżki zaczyna się od /root/.ssh) - `and (user_ssh_directory or fd.name startswith /root/.ssh)`
- oraz (ścieżka absolutna pliku kończy się na authorized_keys lub authorized_keys2) - `and (fd.name endswith authorized_keys or fd.name endswith authorized_keys2)`
- oraz nazwa procesu, który zrobił modyfikację pliku musi istnieć - `and proc_name_exists`

Finalnie chcemy dostać event o zawartości:
```
Ssh keys added to authorized_keys fd.name=%fd.name evt_type=%evt.type user=%user.name user_uid=%user.uid user_loginuid=%user.loginuid proc.name=%proc.name proc.pname=%proc.pname gparent=%proc.aname[2] ggparent=%proc.aname[3] gggparent=%proc.aname[4] proc_exepath=%proc.exepath command=%proc.cmdline terminal=%proc.tty)
```

Priorytet tej reguły: `WARNING`

Tagi, które ta reguła posiada: `[host, container, file, FIM, MITRE_T1098.004_account_manipulation_SSH_keys, MITRE_T1552.004_unsecured_credentials_private_keys]`


## Poprawienie pliku values.yaml

Proszę otworzyć zakładkę Editor i wprowadzić powyższe wymagania dla reguły, finalnie plik powinien mieć budowę (zmieniane i modyfikowane powinno być wszystko co jest poniżej linijki `  custom-rules.yaml: |-` i powyżej linijki `falcosidekick:`)

```
tty: true
kubernetes:
  enabled: true

customRules:
  custom-rules.yaml: |-
    - rule: Nazwa reguły
      desc: >
        Opis reguły w jednej linijce
      condition: >
        open_write 
        and ...
      output: Wygenerowano nowey event...
      priority: INFO
      tags: [host, container]

falcosidekick:
  enabled: true
  webui:
    enabled: false

  config:
    webhook:
      method: POST
      address: "http://3.91.220.165:5678/webhook-test/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" #zostawiacie url jak był
      customheaders: "Content-Type: application/json"
      checkcert: false
```

Następnie należy przeładować pody falco żeby, usunęły się stare i utworzyły nowe z nową utworzoną przez Ciebie regułą, warto zauważyć że zmieniliśmy tylko wymagania dla daemonsetu falco (daemonset zarządza podami, pilnuje żeby były 2 pody falco), nie musimy restartować 2 podów od falcosidekick, ponieważ ich konfiguracja nie została zmieniona

## Wczytanie nowej konfiguracji

Po zapisaniu pliku `values.yaml`, przechodzimy do zakładki `Tab1` i wykonujemy:

```
kubectl rollout restart daemonset/falco -n falco
``` {{exec}}

Czekamy aż nasze pody wystartują, możemy to sprawdzić komendą poniżej (oba pody falco muszą mieć status `Running` co zajmuje ~1min)
```
kubectl get pods -n falco
``` {{exec}}


## Testowanie nowej reguły.

Wystarczy, że dopiszemy nowy klucz `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICR2396foaF4XENyQveTWb2jqCermPbQTK7yUDaRiJUy` do pliku `/root/.ssh/authorized_keys`

```
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICR2396foaF4XENyQveTWb2jqCermPbQTK7yUDaRiJUy" >> /root/.ssh/authorized_keys
``` {{exec}}

Na discordzie kanał `soc-project-team` powinien przyjść alert. Jeśli się tak stanie będzie można przejść do kolejnego zadania.

<br>

<details><summary>Wskazówka 1</summary>
Proszę zwrócić uwagę na wcięcia w pliku values.yaml muszą być odpowiedniej szerokości.
Jak coś nie działa można zawsze wykonać komendę `kubectl describe <nazwa-poda-z-error> -n falco`.

</details>

<br>

<details><summary>Wskazówka 2</summary>
Jak jest Error a wskazówka wyżej nie pomogła to `kubectl describe <nazwa poda> -n falco` i sprawdzić co powoduje błąd. 

</details>

<br>

<br>

<details><summary>Wskazówka 3</summary>
Czater ładnie może napisać w czym jest problem jak się mu wklei logi z powyższych wskazówek.

</details>

<br>

<details><summary>Wskazówka 4</summary>

Jak naprawdę jest jakiś problem proszę przekopiować zawartość poniższą i zapisać plik `values.yaml` i przejść do kroku `Wczytanie nowej konfiguracji`.

```
tty: true
kubernetes:
  enabled: true

customRules:
  custom-rules.yaml: |-
    - rule: Ssh keys added to authorized_keys
      desc: >
        After gaining access, attackers can modify the authorized_keys file to maintain persistence on a victim host. Where authorized_keys files are modified via cloud APIs or command line interfaces, an adversary may achieve privilege escalation on the target  virtual machine if they add a key to a higher-privileged user. This rules aims at detecting any modification to the authorized_keys file, that is usually located under the .ssh directory in any users home directory.
      condition: >
        open_write 
        and (user_ssh_directory or fd.name startswith /root/.ssh)
        and (fd.name endswith authorized_keys or fd.name endswith authorized_keys2)
        and proc_name_exists
      output: Ssh keys added to authorized_keys fd.name=%fd.name evt_type=%evt.type user=%user.name user_uid=%user.uid user_loginuid=%user.loginuid proc.name=%proc.name proc.pname=%proc.pname gparent=%proc.aname[2] ggparent=%proc.aname[3] gggparent=%proc.aname[4] proc_exepath=%proc.exepath command=%proc.cmdline terminal=%proc.tty)
      priority: WARNING
      tags: [host, container, file, FIM, MITRE_T1098.004_account_manipulation_SSH_keys, MITRE_T1552.004_unsecured_credentials_private_keys]


falcosidekick:
  enabled: true
  webui:
    enabled: false

  config:
    webhook:
      method: POST
      address: "http://3.91.220.165:5678/webhook-test/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" #zostawiacie jak było
      customheaders: "Content-Type: application/json"
      checkcert: false
```

</details>

<br>

<details><summary>Wskazówka 5</summary>
🐈🐈🐈🐈

</details>

<br>

<details><summary>Rozwiązanie</summary>
Proszę nie iść na skróty 😿

</details>