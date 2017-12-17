#!/bin/bash -ex
go run *.go \
  -postgres_credentials_path postgres_credentials_dev.json \
  -port 8080 \
  -static_path $PWD
