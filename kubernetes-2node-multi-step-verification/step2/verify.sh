#!/bin/bash

kubectl logs -l app.kubernetes.io/name=falco -n falco -c falco | grep Warning