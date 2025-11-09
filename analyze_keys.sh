#!/usr/bin/env bash
# analyze_keys.sh - szybka analiza pliku .dat pod kątem jawnych kluczy/hasel
# Usage: ./analyze_keys.sh plik.dat

set -euo pipefail
FILE="${1:-}"
if [[ -z "$FILE" || ! -f "$FILE" ]]; then
  echo "Użycie: $0 /pełna/ścieżka/do/plik.dat"
  exit 2
fi

OUTDIR="${FILE}_analysis_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTDIR"
echo "Analiza: $FILE"
echo "Wyniki będą w: $OUTDIR"

# 1) podstawowe info
echo -e "\n--- file / stat ---" | tee "$OUTDIR/01_info.txt"
file "$FILE" | tee -a "$OUTDIR/01_info.txt"
stat "$FILE" | tee -a "$OUTDIR/01_info.txt"

# 2) strings (długość >=6) zapis do pliku
echo -e "\n--- strings (>=6) ---" | tee "$OUTDIR/02_strings_head.txt"
strings -n 6 "$FILE" > "$OUTDIR/02_strings.txt"
head -n 200 "$OUTDIR/02_strings.txt" | tee -a "$OUTDIR/02_strings_head.txt"

# 3) wyszukaj wystąpienia keymeta! i defaultkey z offsetami bajtowymi
echo -e "\n--- znajdź patterny (offsety bajtowe) ---" | tee "$OUTDIR/03_matches.txt"
grep -oba --binary-files=text 'keymeta!' "$FILE" | tee -a "$OUTDIR/03_matches.txt"
grep -oba --binary-files=text 'defaultkey' "$FILE" | tee -a "$OUTDIR/03_matches.txt"

# 4) dla każdego znalezionego offsetu wypisz kontekst (hexdump + ascii) ±128 bajtów
CONTEXT=128
echo -e "\n--- kontekst wokół znalezionych offsetów ---" | tee "$OUTDIR/04_contexts.txt"
( grep -oba --binary-files=text 'keymeta!' "$FILE" || true
  grep -oba --binary-files=text 'defaultkey' "$FILE" || true
) | sort -n | cut -d: -f1 | uniq | while read -r off; do
  echo ">> offset: $off" | tee -a "$OUTDIR/04_contexts.txt"
  # wyciągamy fragment do pliku tymczasowego i robiemy hexdump
  start=$(( off > CONTEXT ? off - CONTEXT : 0 ))
  len=$(( CONTEXT*2 + 256 ))
  dd if="$FILE" bs=1 skip=$start count=$len 2>/dev/null | hexdump -C -v | tee -a "$OUTDIR/04_contexts.txt"
  echo -e "--------------------" | tee -a "$OUTDIR/04_contexts.txt"
done

# 5) znajdź potencjalne base64 i próbuj dekodować (pokazujemy tylko czytelne ASCII)
echo -e "\n--- base64 candidates ---" | tee "$OUTDIR/05_base64.txt"
grep -Eo '[A-Za-z0-9+/]{20,}={0,2}' "$OUTDIR/02_strings.txt" | sort -u > "$OUTDIR/base64_candidates.txt"
head -n 50 "$OUTDIR/base64_candidates.txt" | tee -a "$OUTDIR/05_base64.txt"
# dekoduj pierwsze 30 kandydatów i pokaż strings
head -n 30 "$OUTDIR/base64_candidates.txt" | while read -r s; do
  echo "=== $s ===" >> "$OUTDIR/05_base64_decoded.txt"
  echo "$s" | base64 -d 2>/dev/null | strings -n 4 >> "$OUTDIR/05_base64_decoded.txt" || echo "(nie da się zdekodować lub brak czytelnych znaków)" >> "$OUTDIR/05_base64_decoded.txt"
done

# 6) kandydaci hex
echo -e "\n--- hex candidates (>=32 hex) ---" | tee "$OUTDIR/06_hex.txt"
grep -Eo '[0-9a-fA-F]{32,}' "$OUTDIR/02_strings.txt" | sort -u > "$OUTDIR/hex_candidates.txt"
head -n 50 "$OUTDIR/hex_candidates.txt" | tee -a "$OUTDIR/06_hex.txt"

# 7) hash-like (md5/sha1/sha256) — szybkie wyciągnięcie
echo -e "\n--- hashes found ---" | tee "$OUTDIR/07_hashes.txt"
grep -Eo '\b[a-f0-9]{32}\b' "$OUTDIR/02_strings.txt" | sort -u >> "$OUTDIR/07_hashes.txt" || true
grep -Eo '\b[a-f0-9]{40}\b' "$OUTDIR/02_strings.txt" | sort -u >> "$OUTDIR/07_hashes.txt" || true
grep -Eo '\b[a-f0-9]{64}\b' "$OUTDIR/02_strings.txt" | sort -u >> "$OUTDIR/07_hashes.txt" || true
head -n 200 "$OUTDIR/07_hashes.txt" | tee -a "$OUTDIR/07_hashes.txt"

# 8) entropia (python szybkie obliczenie)
echo -e "\n--- entropia (bits/byte) ---" | tee "$OUTDIR/08_entropy.txt"
python3 - <<'PY' > "$OUTDIR/08_entropy.txt"
import math,sys
b=open("${FILE}","rb").read()
from collections import Counter
if not b:
    print("plik pusty")
    sys.exit(0)
c=Counter(b)
ent=-sum((v/len(b))*math.log2(v/len(b)) for v in c.values())
print("Entropia:",ent,"bits/byte (8=max)")
PY
cat "$OUTDIR/08_entropy.txt" | tee -a "$OUTDIR/08_entropy.txt"

# 9) opcjonalnie binwalk (jeżeli zainstalowany)
echo -e "\n--- binwalk - sprawdzamy i ewentualnie wyodrębniamy ---" | tee "$OUTDIR/09_binwalk.txt"
if command -v binwalk >/dev/null 2>&1; then
  binwalk -e "$FILE" | tee -a "$OUTDIR/09_binwalk.txt" || true
  echo "Jeżeli binwalk wyodrębnił pliki, sprawdź folder _${FILE}.extracted"
else
  echo "binwalk nie jest zainstalowany. Zainstaluj: sudo apt install binwalk" | tee -a "$OUTDIR/09_binwalk.txt"
fi

echo -e "\nAnaliza zakończona. Sprawdź katalog: $OUTDIR"
