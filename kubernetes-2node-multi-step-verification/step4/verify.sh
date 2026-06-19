#!/bin/bash

#test "$(kubectl logs -l app.kubernetes.io/name=falco -n falco -c falco | grep Warning | grep 'Ssh keys added to authorized_keys' | wc -l)" -gt 1
ls