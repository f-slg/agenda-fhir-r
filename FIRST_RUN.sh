#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

echo "[1/3] Instalando/verificando paquetes..."
Rscript scripts/00_install_packages.R

echo "[2/3] Ejecutando preflight..."
Rscript scripts/01_preflight.R

echo "[3/3] Iniciando FHIR Clinical Flow..."
Rscript scripts/02_run_app.R
