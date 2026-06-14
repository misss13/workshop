# Zestawienie środowiska

## Deploy falco na naszym klastrze

### Instalujemy repozytorium helm
```
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update
```{{exec}}

### Instalujemy Falco
```
helm install --replace falco --namespace falco --create-namespace --set tty=true falcosecurity/falco
```{{exec}}

### Sprawdzamy stan deploymentu
```
kubectl get pods -n falco
```{{exec}}

Trzeba poczekać około minutę. Dopiero kiedy po uruchomieniu powyższej komendy będziemy mieć status *Running*, można przejść dalej (status sprawdzamy powyższą komendą):
```
NAME          READY   STATUS     RESTARTS   AGE
falco-q7flx   0/2     Running   0          9s
falco-xp27h   0/2     Running   0          9s
```

### Na co czekamy?
Powyższe komendy uruchamiają na każdym nodzie(maszynie wirtualnej), po jednym podzie(kontenerze) falco, ten pod(kontener) będzie monitorował co aktualnie dzieje się na systemie oraz w kontenerach.

Może to zająć trochę czasu, bo pobiera się na każdy node obraz falco, żeby sprawdzić status wystarczy wykonać powyższą komendę `kubectl get pods -n falco`.