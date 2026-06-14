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

Dopiero kiedy po uruchomieniu powyższej komendy będziemy mieć status:
```
NAME          READY   STATUS     RESTARTS   AGE
falco-q7flx   0/2     Init:0/2   0          9s
falco-xp27h   0/2     Init:0/2   0          9s
```

Można przejść dalej.