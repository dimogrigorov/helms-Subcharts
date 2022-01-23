#!/bin/sh

##############
# Description: Runs Jindent against the Java files to be committed.
#
# Pre-condition: $JINDENT_RUNTIME environment variable is defined.
#
# Usage: ./scripts/jindent.sh [style_file [-checkSum]]
#Script arguments: - style_file - Jindent style rules file
#                  - -checkSum - if JIndent completes successfully the MD5 checksum
#                    of the Jindeted files will be verified.
#                    If it fails  an exit code of 126 will be returned.
##############

# Output style escapes
ERROR="\033[0;31m"
INFO="\033[0;32m"
WARN="\033[0;33m"
BOLD="\033[1m"
NORMAL="\033[0m"

# Exit if JINDENT_RUNTIME environment variable is not defined
if [[ "x$JINDENT_RUNTIME" = 'x' || ! -e "$JINDENT_RUNTIME" || ! -f "$JINDENT_RUNTIME" ]]; then
  echo -e "${ERROR}Environment variable JINDENT_RUNTIME not defined - Jindent failed.${NORMAL}"
  exit 64
fi

# Check whether Jindent style file is not provided as a parameter
STYLE=data-format/ifao-style.xjs
if [[ "$1x" != "x" && -e $1 && -f $1 ]]; then
  STYLE=$1
  shift
fi

# Define whether MD5 hashes must be produced
test "x$1" = "x-checksum"
CHECK_MD5=$?

# Collect files to be Jindented
readarray -t JINDENT_FILES <<< "$(git diff --name-only --diff-filter=ACMR HEAD | grep '\.java$')"

# Collect the md5 hashes of the files to be Jindented
if test $CHECK_MD5 -eq 0 && test -n "$JINDENT_FILES"; then
  declare -A JINDENT_HASHES
  for file in "${JINDENT_FILES[@]}"; do
    file_hash=$(md5sum "$file")
    JINDENT_HASHES[$file]=${file_hash%% *}
  done
fi

# Run Jindent
if test -n "$JINDENT_FILES"; then
  JINDENT_LOG=$("$JINDENT_RUNTIME" -p "$STYLE" "${JINDENT_FILES[@]}" 2>&1)
  EXIT_CODE=$?
else
  EXIT_CODE=0
fi

# If Jindent fails print its execution log
if test $EXIT_CODE -eq 1; then
  echo -e "${ERROR}Jindent failed. Check execution log below."
  echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
  echo "$JINDENT_LOG"
  echo -e "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<${NORMAL}"
else
# If checksum must be calculated of each JIndented file
# verify the checksum and set appropriate exit code
  if test $CHECK_MD5 -eq 0 && test ${#JINDENT_HASHES[@]} -gt 0; then
    readarray -t JINDENT_CHANGED <<< "$(for file in ${!JINDENT_HASHES[@]}; do echo ${JINDENT_HASHES[$file]} $file; done | md5sum --check 2>/dev/null | sed -n 's/: FAIL.*//p')"

    if test -n "$JINDENT_CHANGED"; then
      # Unstage Jindented files from Git index
      git reset -- "${JINDENT_CHANGED[@]}" >/dev/null

      EXIT_CODE=126
    fi
  fi
fi

# Exit with the calculated exit code
exit $EXIT_CODE
