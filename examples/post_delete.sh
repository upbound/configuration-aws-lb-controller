#!/bin/sh

echo "Executing post-delete hook for XAWSLBController"

"${KUBECTL}" wait usages.apiextensions.crossplane.io --all --for=delete --timeout 5m
