#!/bin/bash

#test "$(kubectl logs -l app.kubernetes.io/name=falco -n falco -c falco | grep Warning | grep 'Warning Sensitive file opened' | wc -l)" -gt 1
ls