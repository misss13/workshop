#!/bin/bash

kubectl get pods -n falco -l app.kubernetes.io/name=falco --field-selector=status.phase=Stopped