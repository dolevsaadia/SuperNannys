#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────
#  SuperNanny – One-command Setup Script
#  Usage: ./setup.sh [--dev | --prod | --flutter-only | --backend-only]
# ─────────────────────────────────────────────────────────────────
set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

MODE="${1:---dev}"

echo ""
echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║        SuperNanny Setup v1.0.0           ║${NC}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════╝${NC}"
echo ""

require_cmd() {
  if ! command -v "$1" &>/dev/null; then
    echo -e "${RED}✗ Required: '$1' is not installed.${NC}"
    exit 1
  fi
}

# ── Environment file ─────────────────────────────────────────────
setup_env() {
  echo -e "${CYAN}▸ Setting up environment...${NC}"
  if [ ! -f "backend/.env" ]; then
    cp backend/.env.example backend/.env
    echo -e "${GREEN}  ✓ Created backend/.env from .env.example${NC}"
    echo -e "${YELLOW}  ⚠  Edit backend/.env and set JWT_SECRET before production use!${NC}"
  else
    echo -e "${GREEN}  ✓ backend/.env already exists${NC}"
  fi
}

# ── Backend (Docker) ──────────────────────────────────────────────
setup_backend_docker() {
  require_cmd docker
  require_cmd docker-compose || require_cmd docker

  echo -e "${CYAN}▸ Starting PostgreSQL + Backend with Docker Compose...${NC}"
  docker compose up -d postgres

  echo -e "${CYAN}▸ Waiting for PostgreSQL to be healthy...${NC}"
  for i in {1..30}; do
    if docker compose exec -T postgres pg_isready -U supernanny -d supernanny_db &>/dev/null 2>&1; then
      echo -e "${GREEN}  ✓ PostgreSQL is ready${NC}"
      break
    fi
    sleep 1
    if [ "$i" -eq 30 ]; then
      echo -e "${RED}✗ PostgreSQL failed to start in time.${NC}"
      exit 1
    fi
  done

  echo -e "${CYAN}▸ Installing backend dependencies...${NC}"
  (cd backend && npm install --silent)

  echo -e "${CYAN}▸ Generating Prisma client...${NC}"
  (cd backend && npx prisma generate)

  echo -e "${CYAN}▸ Running database migrations...${NC}"
  (cd backend && DATABASE_URL="postgresql://supernanny:supernanny_secret@localhost:5432/supernanny_db?schema=public" npx prisma migrate deploy)
  echo -e "${GREEN}  ✓ Database schema created${NC}"

  echo -e "${CYAN}▸ Seeding demo data...${NC}"
  (cd backend && DATABASE_URL="postgresql://supernanny:supernanny_secret@localhost:5432/supernanny_db?schema=public" npm run db:seed)
  echo -e "${GREEN}  ✓ Demo data seeded${NC}"

  echo -e "${CYAN}▸ Starting backend...${NC}"
  (cd backend && npm run dev &)

  echo ""
  echo -e "${GREEN}${BOLD}✓ Backend ready at http://localhost:8080${NC}"
}

# ── Backend (Local, no Docker) ────────────────────────────────────
setup_backend_local() {
  require_cmd node
  require_cmd npm
  require_cmd psql

  echo -e "${CYAN}▸ Creating PostgreSQL database...${NC}"
  createdb supernanny_db 2>/dev/null || echo "  Database may already exist"
  psql -c "CREATE USER supernanny WITH PASSWORD 'supernanny_secret';" 2>/dev/null || true
  psql -c "GRANT ALL PRIVILEGES ON DATABASE supernanny_db TO supernanny;" 2>/dev/null || true

  echo -e "${CYAN}▸ Installing backend dependencies...${NC}"
  (cd backend && npm install --silent)

  echo -e "${CYAN}▸ Running database migrations...${NC}"
  (cd backend && npx prisma migrate deploy)

  echo -e "${CYAN}▸ Seeding demo data...${NC}"
  (cd backend && npm run db:seed)

  echo -e "${CYAN}▸ Starting backend in development mode...${NC}"
  (cd backend && npm run dev)
}

# ── Flutter App ───────────────────────────────────────────────────
setup_flutter() {
  require_cmd flutter

  echo -e "${CYAN}▸ Getting Flutter packages...${NC}"
  (cd app && flutter pub get)

  echo -e "${GREEN}  ✓ Flutter packages installed${NC}"
  echo ""
  echo -e "${CYAN}To run the app:${NC}"
  echo "  cd app"
  echo "  flutter run              # runs on connected device"
  echo "  flutter run -d ios       # runs on iOS simulator"
  echo "  flutter run -d android   # runs on Android emulator"
  echo ""
  echo -e "${YELLOW}  Configure API URL in app/lib/core/constants/app_constants.dart${NC}"
  echo -e "${YELLOW}  Change 'localhost' to your machine's IP for physical devices${NC}"
}

# ── Main ──────────────────────────────────────────────────────────
case "$MODE" in
  --dev)
    setup_env
    echo -e "${YELLOW}Choose backend setup:${NC}"
    echo "  1) Docker (recommended) – runs PostgreSQL in Docker"
    echo "  2) Local – requires local PostgreSQL installation"
    read -p "Enter choice [1/2]: " choice
    if [ "$choice" = "2" ]; then
      setup_backend_local
    else
      setup_backend_docker
    fi
    setup_flutter
    ;;
  --backend-only)
    setup_env
    setup_backend_docker
    ;;
  --flutter-only)
    setup_flutter
    ;;
  --docker)
    setup_env
    setup_backend_docker
    ;;
  *)
    echo "Usage: ./setup.sh [--dev | --docker | --flutter-only | --backend-only]"
    exit 1
    ;;
esac

echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║       Setup Complete! 🎉                 ║${NC}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BOLD}Demo credentials (password: Super1234!):${NC}"
echo "  parent1@supernanny.app  → Parent"
echo "  nanny1@supernanny.app   → Nanny"
echo "  admin@supernanny.app    → Admin"
echo ""
echo -e "${BOLD}API:${NC} http://localhost:8080"
echo -e "${BOLD}To enable payments:${NC} Set ENABLE_PAYMENTS=true in backend/.env"
echo ""
