#!/usr/bin/env bash

set -euo pipefail

# Add some color to the script output to make it somewhat readable. It is very verbose
# but it must also be very *readable*, and I think the colors help a little.
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging and error handling functionality. Since we ultimately deploy on the web, the
# script should be very picky about how to handle errors.
log_info() {
  echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $*" >&2
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $*" >&2
}

handle_error() {
  log_error "An error occurred at line $1"
  exit 1
}

trap 'handle_error $LINENO' ERR

# The file name contains the date (yyyy-mm-dd) on which the post was written. Extract
# and store it to be used later. The date will be excluded from the title later on.
extract_date() {
  local filename="$1"
  if [[ $filename =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
    echo "${BASH_REMATCH[1]}"
  else
    echo ""
  fi
}

# Remove date prefix, file extension, replace hyphens with spaces, capitalize words
# The sanitized title *must* be web friendly, as it will be used in various user-facing
# sections of the site.
sanitize_title() {
  local filename="$1"
  echo "$filename" | sed -E 's/^[0-9]{4}-[0-9]{2}-[0-9]{2}-//; s/\.md$//; s/-/ /g; s/\b\w/\u&/g'
}

# Check if command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check if required dependencies are available. The default devshell should
# provide required tools already, but this is here as a sanity check in case
# the user is trying to run the Make script outside the shell, or, without
# direnv.
check_requirements() {
  local missing=0

  for cmd in pandoc jq sassc python; do
    if ! command_exists "$cmd"; then
      log_error "Required command '$cmd' is missing"
      missing=1
    fi
  done

  if [[ $missing -eq 1 ]]; then
    log_error "Please install missing requirements"
    exit 1
  fi
}
