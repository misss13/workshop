# Przetestowanie domyślnych reguł

## Wprowadzenie
W systemach wykorzystujących kernel Linux, plik `/etc/shadow` modyfikowany jest przy tworzeniu nowego użytkownika lub zmianie jego hasła. Nie jest normalnym działaniem odczyt zawartości tego pliku.

Jednym z zadań SOCu w organizacji jest monitorowanie takich niecodziennych działań i sprawdzanie czy zostały one przeprowadzone w ramach zatwierdzonych zadań (tasków). SOC musi wiedzieć czy takie zadanie było przeprowadzone w organizacji celowo, czy nie; w drugim przypadku może być to IoC.
<br>

<details><summary>Rozszerzony opis</summary>
Takie operacje w organizacjach muszą być odnotowane w systemie ticketowania (śledzenia zadań które pracownicy robią, wraz z potwierdzeniami od ich przełożonych np.: Jira). Nikt normalnie nie powinien wypisywać zawartości pliku `/etc/shadow`, oczywiście z uwagi na naprawianie jakiegoś problemu może się to wydarzyć, wymaga to jednak wyjaśnienia oraz ustalenia odpowiedniego wyjątku jeśli odczyt robiony jest okresowo w ramach jakiegoś procesu.

#### Można zapytać dlaczego niby jest to podejrzane?
A po co ktoś miałby czytać plik zawierający hashe haseł wszystkich użytkowników systemowych. Skrypty do wyciągania informacji z serwera, chętnie biorą te dane, do ransomwaru, późniejszej analizy lub odsprzedania. MITRE dla tej operacji definiuje techinikę [T1555](https://attack.mitre.org/techniques/T1555/).

</details>

## Testowana reguła - odczyt z pliku `/etc/shadow`
Przy uruchomieniu falco bez wskazania mu pliku z regułami zostanie użyty [domyślny zestaw reguł](https://github.com/falcosecurity/rules/blob/main/rules/falco_rules.yaml). Poniżej przedstawiono regułę, którą będziemy testować *Read sensitive file untrusted*.


```
- rule: Read sensitive file untrusted
  desc: >
    An attempt to read any sensitive file (e.g. files containing user/password/authentication
    information). Exceptions are made for known trusted programs. Can be customized as needed.
    In modern containerized cloud infrastructures, accessing traditional Linux sensitive files
    might be less relevant, yet it remains valuable for baseline detections. While we provide additional
    rules for SSH or cloud vendor-specific credentials, you can significantly enhance your security
    program by crafting custom rules for critical application credentials unique to your environment.
  condition: >
    open_read
    and sensitive_files
    and proc_name_exists
    and not proc.name in (user_mgmt_binaries, userexec_binaries, package_mgmt_binaries,
     cron_binaries, read_sensitive_file_binaries, shell_binaries, hids_binaries,
     vpn_binaries, mail_config_binaries, nomachine_binaries, sshkit_script_binaries,
     in.proftpd, mandb, salt-call, salt-minion, postgres_mgmt_binaries,
     google_oslogin_
     )
    and not cmp_cp_by_passwd
    and not ansible_running_python
    and not run_by_qualys
    and not run_by_chef
    and not run_by_google_accounts_daemon
    and not user_read_sensitive_file_conditions
    and not mandb_postinst
    and not perl_running_plesk
    and not perl_running_updmap
    and not veritas_driver_script
    and not perl_running_centrifydc
    and not runuser_reading_pam
    and not linux_bench_reading_etc_shadow
    and not user_known_read_sensitive_files_activities
    and not user_read_sensitive_file_containers
  output: Sensitive file opened for reading by non-trusted program | file=%fd.name gparent=%proc.aname[2] ggparent=%proc.aname[3] gggparent=%proc.aname[4] evt_type=%evt.type user=%user.name user_uid=%user.uid user_loginuid=%user.loginuid process=%proc.name proc_exepath=%proc.exepath parent=%proc.pname command=%proc.cmdline terminal=%proc.tty
  priority: WARNING
  tags: [maturity_stable, host, container, filesystem, mitre_credential_access, T1555]
```

### Poniżej spisano makra oraz listy wykorzystane w powyższej regule
Makro zastępuje długi ciąg lub zbiór warunków, celem łatwiejszego czytania reguł. 
Lista zawiera w sobie zmienne np.: nazwy plików, programów, nazw folderów, adresów IP.


Makro **open_read** prosi żeby falco monitorowało system calle  wykorzystywane do odczytu pliku. Oczywiście monitorowanie wszystkich odczytów plików nie miałoby sensu - byłoby ich zbyt dużo.
```
- macro: open_read
  condition: (evt.type in (open,openat,openat2) and evt.is_open_read=true and fd.typechar='f' and fd.num>=0)
```

Makro **sensitive_files** plików które zostały oznaczone jako wrażliwe pliki. W tym makro zostało zrobione odwołanie do listy *sensitive_file_names* zawierającej plik `/etc/shadow`, którego odczyt będziemy testować.
```
- macro: sensitive_files
  condition: >
    (fd.name in (sensitive_file_names) or
      fd.directory in (/etc/sudoers.d, /etc/pam.d))
```

Lista **sensitive_file_names** zawieraja nazwy wrażliwych plików.
```
- list: sensitive_file_names
  items: [/etc/shadow, /etc/sudoers, /etc/pam.conf, /etc/security/pwquality.conf]
```

Makro **proc_name_exists** wymaga, żeby proces posiadał nazwę.
```
- macro: proc_name_exists
  condition: (not proc.name in ("<NA>","N/A"))
```

## Jak interpretować regułę
Dla uproszczenia:
```
- rule: Read sensitive file untrusted

  desc: >
    Opis reguły

  condition: >
    open_read #ktoś otworzy plik
    and (fd.name in [/etc/shadow, ...]) #oraz plik będzie mieć nazwę /etc/shadow
    and not proc.name in ("<NA>","N/A") #proces będzie mieć nazwę

    and not [...] #inne wyjątki

  output: Sensitive file opened for reading by non-trusted program | file=%fd.name gparent=%proc.aname[2] ggparent=%proc.aname[3] gggparent=%proc.aname[4] evt_type=%evt.type user=%user.name user_uid=%user.uid user_loginuid=%user.loginuid process=%proc.name proc_exepath=%proc.exepath parent=%proc.pname command=%proc.cmdline terminal=%proc.tty

  priority: WARNING

  tags: [maturity_stable, host, container, filesystem, mitre_credential_access, T1555]
```
Powyższa reguła może być znaleziona [tutaj](https://github.com/falcosecurity/rules/blob/b71a8c0df60b005dc3cd716ade0386d9c2324a1f/rules/falco_rules.yaml#L397).

## Wywołanie reguły
W tym celu spróbujemy dwóch podejść: na nowo utworzonym podzie (kontenerze) oraz na aktualnym podzie (maszynie wirtualnej *controlplane*)

### Na podzie
Tworzymy na początek nowy pod z aplikacją ngnix

```
kubectl create deployment nginx --image=nginx
```{{exec}}

czekamy chwilę i sprawdzamy stan poda, aż będzie taki:
```
NAME                     READY   STATUS    RESTARTS   AGE
nginx-56c45fd5ff-jm77z   1/1     Running   0          21s
```

możemy to sprawdzić komendą
```
kubectl get pods
```{{exec}}

a następnie uruchamiamy, polecenie którym uruchomimy komendę `cat /etc/shadow` już na nowo utworzonym podzie
```
kubectl exec -it $(kubectl get pods --selector=app=nginx -o name) -- cat /etc/shadow
```{{exec}}

#### Sprawdzenie 
Poniższa komenda pozwoli na sprawdzenie czy faktycznie udało się nam złapać odczyt pliku `/etc/shadow`
```
kubectl logs -l app.kubernetes.io/name=falco -n falco -c falco | grep Warning | grep ngnix
```{{exec}}

### Na nodzie
Warto zauważyć że kiedy wpisujemy komendę `id` otrzymujemy:
```
root@controlplane:~$ id
uid=0(root) gid=0(root) groups=0(root)
```
po sprawdzeniu pliku `/etc/passwd`:
```
root@controlplane:~$ cat /etc/passwd | grep 0:0
root:x:0:0:root:/root:/bin/bash
kc-internal:x:0:0::/root:/bin/bash
```
oznacza to że tak naprawdę wykonujemy polecenia jako użytkownik `kc-internal` nie koniecznie root