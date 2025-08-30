set -euo pipefail

VCP=60
A=0x0f
B=0x19
DDC=${DDCUTIL_BIN:-ddcutil}

err() { printf "toggle-input: %s\n" "$*" >&2; }

command -v "$DDC" >/dev/null 2>&1 || { err "ddcutil not found"; exit 1; }

# Read current value (short value after sl=)
read_current() {
  "$DDC" getvcp "$VCP" 2>/dev/null | sed -n 's/.*sl=\(0x[0-9a-fA-F]\+\).*/\1/p' | head -n1
}

CURRENT=$(read_current || true)

if [[ -z "${CURRENT}" ]]; then
  err "could not read current input"
  exit 1
fi

case "$CURRENT" in
  "$A") NEXT=$B ;;
  "$B") NEXT=$A ;;
  *)
    err "unknown current value: $CURRENT (expected $A or $B)"
    exit 1
    ;;
esac

echo "Current: $CURRENT -> Switching to: $NEXT"
"$DDC" setvcp "$VCP" "$NEXT"

# Wait a bit; some monitors need time to apply & respond
for i in 1 2 3; do
  sleep 1
  NEW=$(read_current || true)
  if [[ "$NEW" == "$NEXT" ]]; then
    echo "Switched successfully: $NEW"
    exit 0
  fi
done

err "failed to confirm switch (last read: ${NEW:-none})"
exit 1
