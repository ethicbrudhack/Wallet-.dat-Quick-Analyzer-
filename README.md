🧩 Wallet .dat Quick Analyzer (Untested Forensic Utility)

⚠️ Educational / Research / Forensic Use Only

This script performs a lightweight forensic inspection of a binary file (for example, a legacy Bitcoin wallet.dat) and extracts any readable or encoded information that might be present — such as printable text, base64 fragments, hexadecimal strings, or metadata markers.

⚠️ It does not decrypt or extract private keys, and it should only be used on files you own or are authorized to analyze.

This is an experimental Bash utility — not tested for all environments and may contain errors.

📘 Overview

analyze_keys.sh is a quick diagnostic Bash script that scans a binary .dat file (such as a Berkeley DB–based wallet) for potential text fragments, metadata, or encoded data.
It produces a structured output directory containing text reports and extracts.

This kind of analysis is commonly used in digital forensics, wallet recovery research, or data integrity inspection — for educational and lawful purposes only.

⚙️ Features

📄 Extracts printable strings (strings -n 6)

🗝 Searches for wallet-related markers such as keymeta! or defaultkey

🔍 Displays context around found offsets (via dd and hexdump)

🔡 Finds and decodes Base64-like sequences

🔢 Detects hexadecimal strings and potential hash values (MD5, SHA-1, SHA-256)

📈 Estimates file entropy (bits per byte) using an inline Python snippet

🧰 Optionally runs binwalk to detect embedded files or structures

🗂 Saves all results in a timestamped output directory for easy review

▶️ Usage
chmod +x analyze_keys.sh
./analyze_keys.sh /full/path/to/wallet.dat


Example output:

Analysis: wallet.dat
Results will be in: wallet.dat_analysis_20251109_134812


The script creates a new folder named:

<filename>_analysis_<YYYYMMDD_HHMMSS>/


containing multiple numbered text reports.

🧠 What Each Step Does
Step	File	Description
1️⃣	01_info.txt	Basic file info via file and stat
2️⃣	02_strings.txt	Extracts printable strings (min length 6)
3️⃣	03_matches.txt	Finds offsets of keymeta! and defaultkey markers
4️⃣	04_contexts.txt	Shows hex + ASCII context ±128 bytes around found offsets
5️⃣	05_base64.txt / 05_base64_decoded.txt	Finds possible Base64 data and decodes first 30 entries
6️⃣	06_hex.txt	Lists hex strings ≥32 characters
7️⃣	07_hashes.txt	Extracts 32, 40, and 64-character hash-like strings
8️⃣	08_entropy.txt	Computes Shannon entropy (0–8 bits/byte)
9️⃣	09_binwalk.txt	Optional binwalk analysis and extraction results
🧰 Dependencies

The script relies on standard UNIX tools and optional utilities:

Tool	Purpose	Required
bash	main shell interpreter	✅
grep, strings, dd, hexdump, file, stat, sort, uniq	text and binary processing	✅
python3	entropy calculation	✅
binwalk	detect embedded files	optional
Install optional tools

On Debian/Ubuntu:

sudo apt install binwalk

🧪 Example Use Case

Run the analyzer on a copy of an old wallet or binary database file:

./analyze_keys.sh ~/backups/wallet_old.dat


You might discover readable labels such as:

---- strings ----
label
Main Account
2014
defaultkey
keymeta!


and entropy output like:

Entropy: 7.98 bits/byte (8=max)


This helps determine whether the file is encrypted, compressed, or partially corrupted.

⚠️ Warnings & Limitations

This tool does not decrypt wallet files or recover private keys.

It is meant for educational forensic analysis only.

Results are heuristic — many extracted strings may be unrelated or meaningless.

It has been tested only on Linux/macOS and may not work identically on Windows.

The script may generate large output directories for big files.

🪪 License & Ethics

MIT License — provided “as is,” without warranty.
You may reuse or modify this tool for research or educational purposes, but do not use it to inspect data you do not own.
Unauthorized analysis of other people’s wallet files is unethical and potentially illegal.


BTC donation address: bc1q4nyq7kr4nwq6zw35pg0zl0k9jmdmtmadlfvqhr
