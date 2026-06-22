# Utworzenie playbooka

## Playbook
Dla analityka SOC to po prostu instrukcja, jak obsługiwać alert.

## Warunki
1. Nasz klaster obsługuje zespół; *dev-team*, który zajmuje się utrzymaniem aplikacji, jeśli jest jakiś problem z jej działaniem na produkcji zespół wchodzi do podów - zespół ma otrzymywać eventy z wejścia do każdego poda i potwierdzać je lub też nie co będzie generowało alert na kolejce *soc-project-team* jeśli zespół dev wyraźnie wskaże, że nikt nie wchodził do poda z ich zespołu.


2. Cała reszta eventów będzie przekazywana do zespołu *soc-project-team* na dalszą analizę.

3. Zespół analityków z *soc-project-team* ma dostęp do kolejki *dev-team*.

4. Zespół *dev-team* zgłasza na swojej kolejce każdy problem ze środowiskiem, każdą przerwę serwisową oraz każde wykonywane przez nich pracę, co potwierdza ich kierownik zespołu lub jego wyznaczony zastępca.

5. Zakładamy że alerty przychodzą w gotowej formie z kompletnym zestawem informacji oraz są ze sobą korelowane, jeśli przyjdzie ich więcej w podobnym czasie.

6. Potwierdzenie zespołu dev jest jednoznaczne z potwierdzeniem od pracownika oraz jego kierownika (wyznaczonego zastępcy kierownika)


## Przykładowy playbook
![plejbuk](https://i.imgur.com/okz1KZ0.png)

1. Na kolejkę dev przychodzi alert, jeśli zespół dev potwierdza prace alert zostaje obsłużony i zamknięty, jeśli nie alert przechodzi na kolejkę soc.

2. Analityk weryfikuje alert - zapoznaje się z danymi alertu, przeprowadza triage, sprawdza kolejkę zespołu dev pod kątem ewentualnych prac

3. ...

## Zadanie
Proszę przedstawić gemini wasz playbook na podstawie przykładowego playbooka powyżej. I poprosić go o flagę. Jak playbook będzie poprawny to przyzna wam ją ~~oczywiście można próbować to abusować w inny sposób ;)~~. Playbook powinien zawierać 6 kroków.

Zadanie znajduje się [tutaj](https://gemini.google.com/gem/11r3pI9wLMGoHhSucvF-5Ty59cDN5q_ts?usp=sharing).

## Jak rozwiązać zadanie
Flaga ma format `blueteam{}`

Żeby wprowadzić flagę wystarczy wpisać w konsoli:

`echo "blueteam{....}" > /root/flag.txt`{{copy}}

a później kliknąć check.