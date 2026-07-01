#!/usr/bin/env bash
# FileBrowser web file manager on :8080, login admin / WEB_PASSWORD.
# DB is recreated each boot (it's just a file index — no important state).
DB=/workspace/.filebrowser.db
rm -f "$DB"
filebrowser config init --database "$DB"
filebrowser config set --database "$DB" --address 0.0.0.0 --port 8080 --root /workspace
filebrowser users add admin "${WEB_PASSWORD:-comfy}" --perm.admin --database "$DB"
exec filebrowser --database "$DB"
