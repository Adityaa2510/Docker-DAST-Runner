
#!/bin/sh
set -eu

MODE=""
TARGET=""
REPORT="zap-report.html"
WORKSPACE="/zap/wrk"

usage() {
  cat <<'EOF'
Docker DAST Runner

Usage:
  docker run --rm -v "${PWD}:/zap/wrk/:rw" IMAGE \
    --mode baseline|full|api \
    --target URL_OR_SPEC \
    --report REPORT.html

Options:
  --mode       baseline, full, or api
  --target     Web URL or mounted OpenAPI specification
  --report     Report filename (default: zap-report.html)
  --help       Show this help message

Examples:
  --mode baseline --target http://host.docker.internal:3000
  --mode full --target http://host.docker.internal:3000
  --mode api --target /zap/wrk/openapi.yaml
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --mode)
      [ "$#" -ge 2 ] || { echo "Missing value for --mode" >&2; exit 2; }
      MODE="$2"
      shift 2
      ;;
    --target)
      [ "$#" -ge 2 ] || { echo "Missing value for --target" >&2; exit 2; }
      TARGET="$2"
      shift 2
      ;;
    --report)
      [ "$#" -ge 2 ] || { echo "Missing value for --report" >&2; exit 2; }
      REPORT="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

case "$MODE" in
  baseline|full|api) ;;
  *)
    echo "Error: --mode must be baseline, full, or api" >&2
    exit 2
    ;;
esac

if [ -z "$TARGET" ]; then
  echo "Error: --target is required" >&2
  exit 2
fi

if [ ! -d "$WORKSPACE" ]; then
  echo "Error: /zap/wrk is not mounted" >&2
  exit 2
fi

case "$REPORT" in
  ""|*/*|*\\*)
    echo "Error: --report must be a filename, not a path" >&2
    exit 2
    ;;
esac

cd "$WORKSPACE"

case "$MODE" in
  baseline)
    echo "Starting OWASP ZAP baseline scan..."
    set -- zap-baseline.py -t "$TARGET" -r "$REPORT"
    ;;
  full)
    echo "WARNING: Active scan selected. Use only on authorized targets." >&2
    set -- zap-full-scan.py -t "$TARGET" -r "$REPORT"
    ;;
  api)
    case "$TARGET" in
      /zap/wrk/*) ;;
      *)
        echo "Error: API target must be a file inside /zap/wrk" >&2
        exit 2
        ;;
    esac

    if [ ! -f "$TARGET" ]; then
      echo "Error: API specification not found: $TARGET" >&2
      exit 2
    fi

    echo "Starting OWASP ZAP API scan..."
    set -- zap-api-scan.py -t "$TARGET" -f openapi -r "$REPORT"
    ;;
esac

exec "$@"