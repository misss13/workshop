Everything can also be found on: https://falco.org/docs

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
kubectl wait pods --for=condition=Ready --all -n falco
```{{exec}}

Jak wszystko działa można przejść do kolejnego kroku