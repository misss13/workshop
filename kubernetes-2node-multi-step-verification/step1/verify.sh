#!/bin/bash

test "$(kubectl get pods -n falco --no-headers | grep Running | wc -l)" -eq 2