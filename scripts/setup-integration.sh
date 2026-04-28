#!/usr/bin/env bash
# =============================================================================
# ioDesk Integration Setup - Hermes Agent + ioDesk-3 + LocalAGI-ionet
# =============================================================================
# Run this once to prepare the environment for the integration.
#
# Usage:
#   ./scripts/setup-integration.sh
#
# Then start everything:
#   cd ../iodesk-3 && docker compose --profile mcp up -d
#   cd ../LocalAGI-ionet && docker compose -f docker-compose.yaml up -d
#   cd ../hermes-iodesk && HERMES_UID=$(id -u) docker compose \
#     -f docker-compose.integration.yml up -d
# =============================================================================
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

info()  { echo -e "${CYAN}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}   $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
fail()  { echo -e "${RED}[FAIL]${NC} $*"; }

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HERMES_HOME="${HOME}/.hermes"

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  ioDesk Integration Setup                                  ${NC}"
echo -e "${CYAN}  Hermes Agent ↔ ioDesk-3 ↔ LocalAGI-ionet                 ${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo ""

# ── Step 1: Check dependencies ────────────────────────────────────────────
info "Step 1: Checking dependencies..."

if ! command -v docker &> /dev/null; then
    fail "Docker not found. Install Docker first."
    exit 1
fi
ok "Docker found: $(docker --version)"

if ! docker compose version &> /dev/null; then
    fail "Docker Compose not found."
    exit 1
fi
ok "Docker Compose found: $(docker compose version)"

# ── Step 2: Create Docker network ─────────────────────────────────────────
info "Step 2: Creating Docker network 'iodesk-internal'..."
if docker network inspect iodesk-internal &>/dev/null; then
    ok "Network 'iodesk-internal' already exists"
else
    docker network create iodesk-internal --driver bridge
    ok "Network 'iodesk-internal' created"
fi

# ── Step 3: Build Hermes image ────────────────────────────────────────────
info "Step 3: Building Hermes Agent Docker image..."
cd "$PROJECT_DIR"
docker compose -f docker-compose.integration.yml build
ok "Hermes image built"

# ── Step 4: Initialize Hermes config ─────────────────────────────────────
info "Step 4: Initializing Hermes configuration..."
mkdir -p "$HERMES_HOME"/{cron,sessions,logs,hooks,memories,skills,skins,plans,workspace,home}

# Copy example configs if not present
if [ ! -f "$HERMES_HOME/.env" ]; then
    cp "$PROJECT_DIR/.env.example" "$HERMES_HOME/.env"
    warn "Created $HERMES_HOME/.env — EDIT this file with your API keys!"
else
    ok "$HERMES_HOME/.env exists"
fi

if [ ! -f "$HERMES_HOME/config.yaml" ]; then
    cp "$PROJECT_DIR/cli-config.yaml.example" "$HERMES_HOME/config.yaml"
    warn "Created $HERMES_HOME/config.yaml — review and edit as needed"
else
    ok "$HERMES_HOME/config.yaml exists"
fi

# ── Step 5: Verify ioDesk-3 repo exists nearby ───────────────────────────
info "Step 5: Checking sibling repositories..."
IODESK_DIR="$(dirname "$PROJECT_DIR")/iodesk-3"
LOCALAGI_DIR="$(dirname "$PROJECT_DIR")/LocalAGI-ionet"

if [ -d "$IODESK_DIR" ]; then
    ok "ioDesk-3 found at $IODESK_DIR"
else
    warn "ioDesk-3 not found at $IODESK_DIR (expected for standalone setup)"
fi

if [ -d "$LOCALAGI_DIR" ]; then
    ok "LocalAGI-ionet found at $LOCALAGI_DIR"
else
    warn "LocalAGI-ionet not found at $LOCALAGI_DIR (expected for standalone setup)"
fi

# ── Summary ────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Setup Complete!                                           ${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${YELLOW}IMPORTANT:${NC} Edit ${HERMES_HOME}/.env and add your API keys:"
echo -e "    - ${CYAN}OPENROUTER_API_KEY${NC} (or your LLM provider)"
echo -e "    - ${CYAN}HERMES_IODESK_MCP_TOKEN${NC} (from ioDesk .env IODESK_MCP_TOKEN)"
echo ""
echo -e "  ${YELLOW}Start order:${NC}"
echo ""
echo -e "  ${GREEN}1.${NC} ioDesk-3:"
echo -e "     cd ${IODESK_DIR}"
echo -e "     docker compose --profile mcp up -d"
echo ""
echo -e "  ${GREEN}2.${NC} LocalAGI-ionet (optional):"
echo -e "     cd ${LOCALAGI_DIR}"
echo -e "     docker compose -f docker-compose.yaml up -d"
echo ""
echo -e "  ${GREEN}3.${NC} Hermes Agent:"
echo -e "     cd ${PROJECT_DIR}"
echo -e "     HERMES_UID=\$(id -u) HERMES_GID=\$(id -g) \\"
echo -e "       docker compose -f docker-compose.integration.yml up -d"
echo ""
echo -e "  ${YELLOW}Check connectivity:${NC}"
echo -e "     docker exec hermes hermes mcp test iodesk"
echo ""
