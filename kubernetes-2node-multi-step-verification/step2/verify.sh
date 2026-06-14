#!/bin/bash

test "$(kubectl logs -l app.kubernetes.io/name=falco -n falco -c falco | grep Warning | wc -l)" -gt 1