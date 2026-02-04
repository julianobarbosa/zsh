#!/bin/bash
# Test All 24 Voice Configurations (23 unique)
# Press Enter between each voice to proceed
# Usage: ./test-all-voices.sh [--single [NUM]] [--select] [--help]

ENDPOINT="http://localhost:8888/notify"
PASS=0
FAIL=0
RESULTS=()
MODE="batch"
SINGLE_NUM=""

# --- Usage ---
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  --single [NUM]  Interactive mode: test one voice at a time, wait for
                  keypress between each. Optionally pass a voice number
                  (1-23) to test only that voice.
  --select        Multi-select menu: pick which voices to test.
  --help          Show this help message.

Voices:
   1  default (Adam)              13  ux-designer (Nathan)
   2  security (Jason)            14  agent-builder (Louis)
   3  intern (Valf)               15  module-builder (Louis)
   4  bmad-master (Adam)          16  workflow-builder (John)
   5  analyst (John)              17  brainstorming-coach (Montana)
   6  architect (Louis)           18  creative-problem-solver (Jason)
   7  dev (James)                 19  design-thinking-coach (Montana)
   8  pm (Adam)                   20  innovation-strategist (Jason)
   9  quick-flow-solo-dev (James) 21  presentation-master (Montana)
  10  quinn (John)                22  storyteller (Kennedy)
  11  sm (James)                  23  tea (John)
  12  tech-writer (Kennedy)

Examples:
  $(basename "$0")              # Run all 23 voices, Enter between each
  $(basename "$0") --single     # Interactive: one at a time, press Enter
  $(basename "$0") --single 6   # Test only voice #6 (architect)
  $(basename "$0") --select     # Multi-select menu to pick voices
EOF
  exit 0
}

# --- Parse args ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --single)
      MODE="single"
      if [[ -n "$2" && "$2" =~ ^[0-9]+$ ]]; then
        SINGLE_NUM="$2"
        shift
      fi
      shift
      ;;
    --select)
      MODE="select"
      shift
      ;;
    --help|-h)
      usage
      ;;
    *)
      echo "Unknown option: $1"
      usage
      ;;
  esac
done

# --- Voice definitions: num|key|voice_id|stability|similarity|message ---
VOICES=(
  "1|default (Adam)|s3TPKV1kjDlVtZbl4Ksh|0.50|0.75|Voice system initialized. All configurations loaded successfully."
  "2|security (Jason)|lKMAeQD7Brvj7QCWByqK|0.32|0.88|Vulnerability scan complete. Two critical findings require immediate attention."
  "3|intern (Valf)|nNXPmxHfg9PtGzFxr9Zd|0.30|0.85|I just discovered something incredible in the codebase. This changes everything!"
  "4|bmad-master (Adam)|s3TPKV1kjDlVtZbl4Ksh|0.45|0.78|Loading all resources. Three workflows available. Select your next operation."
  "5|analyst (John)|7zqwmkjHFUiXmYUiCluz|0.58|0.82|Market patterns reveal a fascinating opportunity. The data tells a compelling story."
  "6|architect (Louis)|8x8Otoub1daqoxY72hug|0.75|0.78|The system design balances scalability with simplicity. Boring technology wins."
  "7|dev (James)|P9S3WZL3JE8uQqgYH5B7|0.72|0.85|All tests passing. Story acceptance criteria met. Ready for code review."
  "8|pm (Adam)|s3TPKV1kjDlVtZbl4Ksh|0.42|0.76|Why does the user need this feature? Lets dig deeper into the real problem."
  "9|quick-flow-solo-dev (James)|P9S3WZL3JE8uQqgYH5B7|0.65|0.82|Tech spec complete. Moving straight to implementation. No ceremony needed."
  "10|quinn (John)|7zqwmkjHFUiXmYUiCluz|0.60|0.80|Test coverage at ninety-two percent. Three edge cases need additional validation."
  "11|sm (James)|P9S3WZL3JE8uQqgYH5B7|0.70|0.82|Sprint backlog refined. All stories have clear acceptance criteria and estimates."
  "12|tech-writer (Kennedy)|c8GqgOMlDjKmhWVDfhvI|0.50|0.85|Documentation updated with clear examples. Complex concepts simplified for the team."
  "13|ux-designer (Nathan)|mGYySblCQdgQw8L0mOq3|0.48|0.80|The user journey reveals friction at checkout. Let me show you their story."
  "14|agent-builder (Louis)|8x8Otoub1daqoxY72hug|0.72|0.80|Agent architecture validated against BMAD Core standards. All compliance checks pass."
  "15|module-builder (Louis)|8x8Otoub1daqoxY72hug|0.70|0.78|Module integration patterns established. Dependencies mapped across the ecosystem."
  "16|workflow-builder (John)|7zqwmkjHFUiXmYUiCluz|0.65|0.80|Workflow states defined with clear transitions. Error handling covers all edge cases."
  "17|brainstorming-coach (Montana)|5i0xmPB5fWW7Nuat2Wf9|0.22|0.88|YES AND! Build on that wild idea! The crazier the better at this stage!"
  "18|creative-problem-solver (Jason)|lKMAeQD7Brvj7QCWByqK|0.25|0.85|AHA! The root cause was hiding in plain sight. Every problem reveals its weakness."
  "19|design-thinking-coach (Montana)|5i0xmPB5fWW7Nuat2Wf9|0.28|0.86|Feel what the user feels. Empathy is not optional, it is the foundation."
  "20|innovation-strategist (Jason)|lKMAeQD7Brvj7QCWByqK|0.30|0.82|The market rewards genuine new value. Incremental thinking leads to obsolescence."
  "21|presentation-master (Montana)|5i0xmPB5fWW7Nuat2Wf9|0.25|0.88|What if we tried THIS? Bold visual choices make the audience remember your message."
  "22|storyteller (Kennedy)|c8GqgOMlDjKmhWVDfhvI|0.40|0.82|Once upon a time, in a world of complex systems, a simple solution emerged."
  "23|tea (John)|7zqwmkjHFUiXmYUiCluz|0.55|0.82|Risk assessment complete. Coverage scales with business impact. Ship with confidence."
)

TOTAL=${#VOICES[@]}

# --- Send a single voice test ---
send_test() {
  local num=$1 key=$2 voice_id=$3 stability=$4 similarity=$5 message=$6

  printf "\n[%02d/%d] Testing: %-25s " "$num" "$TOTAL" "$key"

  response=$(curl -s -w "\n%{http_code}" -X POST "$ENDPOINT" \
    -H "Content-Type: application/json" \
    -d "{
      \"title\": \"Voice Test: $key\",
      \"message\": \"$message\",
      \"voice_enabled\": true,
      \"voice_id\": \"$voice_id\",
      \"voice_settings\": {
        \"stability\": $stability,
        \"similarity_boost\": $similarity
      }
    }")

  http_code=$(echo "$response" | tail -1)
  body=$(echo "$response" | head -1)

  if [ "$http_code" = "200" ]; then
    printf "✅ PASS (HTTP %s)" "$http_code"
    PASS=$((PASS + 1))
    RESULTS+=("✅ $key")
  else
    printf "❌ FAIL (HTTP %s) %s" "$http_code" "$body"
    FAIL=$((FAIL + 1))
    RESULTS+=("❌ $key (HTTP $http_code)")
  fi
}

# --- Parse a voice entry and call send_test ---
run_voice() {
  local entry="$1"
  IFS='|' read -r num key voice_id stability similarity message <<< "$entry"
  send_test "$num" "$key" "$voice_id" "$stability" "$similarity" "$message"
}

# --- Multi-select menu ---
run_select_menu() {
  local cursor=0
  local -a selected

  for ((i = 0; i < TOTAL; i++)); do selected[$i]=0; done

  draw_menu() {
    tput cup 0 0  # move to top-left

    printf "==========================================\n"
    printf "  Voice Multi-Select Menu\n"
    printf "  ↑↓ Navigate  Space Toggle  a All  n None\n"
    printf "  Enter Run selected  q Quit\n"
    printf "==========================================\n"

    for ((i = 0; i < TOTAL; i++)); do
      IFS='|' read -r num key _ _ _ _ <<< "${VOICES[$i]}"
      local check=" "
      [[ ${selected[$i]} -eq 1 ]] && check="✓"
      if [[ $i -eq $cursor ]]; then
        printf "  \033[7m [%s] %2d  %-35s \033[0m\n" "$check" "$num" "$key"
      else
        printf "   [%s] %2d  %-35s \n" "$check" "$num" "$key"
      fi
    done

    local count=0
    for ((i = 0; i < TOTAL; i++)); do
      [[ ${selected[$i]} -eq 1 ]] && ((count++))
    done
    tput el  # clear rest of line
    printf "\n  %d voice(s) selected" "$count"
    tput el
    printf "\n"
  }

  tput civis  # hide cursor
  tput clear  # clear screen once

  draw_menu

  while true; do
    IFS= read -rsn1 key
    case "$key" in
      $'\e')
        read -rsn2 seq
        case "$seq" in
          '[A') cursor=$(( (cursor - 1 + TOTAL) % TOTAL )) ;;
          '[B') cursor=$(( (cursor + 1) % TOTAL )) ;;
        esac
        ;;
      ' ')
        selected[$cursor]=$(( 1 - selected[$cursor] ))
        ;;
      a|A)
        for ((i = 0; i < TOTAL; i++)); do selected[$i]=1; done
        ;;
      n|N)
        for ((i = 0; i < TOTAL; i++)); do selected[$i]=0; done
        ;;
      ''|$'\n')
        break
        ;;
      q|Q)
        tput cnorm
        tput clear
        exit 0
        ;;
    esac
    draw_menu
  done

  tput cnorm  # restore cursor
  tput clear  # clean up before output

  # Collect selected indices
  SELECTED_INDICES=()
  for ((i = 0; i < TOTAL; i++)); do
    [[ ${selected[$i]} -eq 1 ]] && SELECTED_INDICES+=("$i")
  done
}

# --- Single voice by number ---
if [[ "$MODE" == "single" && -n "$SINGLE_NUM" ]]; then
  if [[ "$SINGLE_NUM" -lt 1 || "$SINGLE_NUM" -gt "$TOTAL" ]]; then
    echo "Error: voice number must be between 1 and $TOTAL"
    exit 1
  fi

  echo "=========================================="
  echo "  Voice Test: #$SINGLE_NUM"
  echo "=========================================="

  run_voice "${VOICES[$((SINGLE_NUM - 1))]}"
  echo ""
  exit 0
fi

# --- Select mode ---
if [[ "$MODE" == "select" ]]; then
  run_select_menu

  if [[ ${#SELECTED_INDICES[@]} -eq 0 ]]; then
    echo -e "\nNo voices selected."
    exit 0
  fi

  echo ""
  echo "=========================================="
  echo "  Testing ${#SELECTED_INDICES[@]} selected voice(s)"
  echo "  Press Enter after each voice, q to quit"
  echo "=========================================="
  echo "Start: $(date '+%H:%M:%S')"

  for idx in "${SELECTED_INDICES[@]}"; do
    run_voice "${VOICES[$idx]}"
    echo ""

    # Wait for user before next voice (skip on last)
    if [[ "$idx" != "${SELECTED_INDICES[-1]}" ]]; then
      printf "\n  ▶ Press Enter when ready for next voice (q to quit): "
      read -r input
      if [[ "$input" == "q" || "$input" == "Q" ]]; then
        IFS='|' read -r num _ _ _ _ _ <<< "${VOICES[$idx]}"
        echo -e "\nStopped by user after voice #$num"
        break
      fi
    fi
  done

# --- Interactive single mode ---
elif [[ "$MODE" == "single" ]]; then
  echo "=========================================="
  echo "  Voice Configuration Test Suite"
  echo "  $TOTAL voices | INTERACTIVE mode"
  echo "  Press Enter after each voice, q to quit"
  echo "=========================================="
  echo "Start: $(date '+%H:%M:%S')"

  for entry in "${VOICES[@]}"; do
    run_voice "$entry"
    echo ""

    IFS='|' read -r num _ _ _ _ _ <<< "$entry"
    if [[ "$num" -lt "$TOTAL" ]]; then
      printf "\n  ▶ Press Enter when ready for next voice (q to quit): "
      read -r input
      if [[ "$input" == "q" || "$input" == "Q" ]]; then
        echo -e "\nStopped by user after voice #$num"
        break
      fi
    fi
  done

# --- Batch mode (default) ---
else
  echo "=========================================="
  echo "  Voice Configuration Test Suite"
  echo "  $TOTAL voices | Press Enter after each voice"
  echo "=========================================="
  echo "Start: $(date '+%H:%M:%S')"

  for i in "${!VOICES[@]}"; do
    run_voice "${VOICES[$i]}"
    echo ""

    IFS='|' read -r num _ _ _ _ _ <<< "${VOICES[$i]}"
    if [[ "$num" -lt "$TOTAL" ]]; then
      printf "\n  ▶ Press Enter when ready for next voice (q to quit): "
      read -r input
      if [[ "$input" == "q" || "$input" == "Q" ]]; then
        echo -e "\nStopped by user after voice #$num"
        break
      fi
    fi
  done
fi

# --- Summary ---
echo -e "\n\n=========================================="
echo "  TEST SUMMARY"
echo "=========================================="
echo "End: $(date '+%H:%M:%S')"
echo "Total: ${#RESULTS[@]} | Pass: $PASS | Fail: $FAIL"
echo ""
for r in "${RESULTS[@]}"; do
  echo "  $r"
done
echo "=========================================="

if [ $FAIL -eq 0 ]; then
  echo "🎉 ALL VOICES PASSED!"
else
  echo "⚠️  $FAIL voice(s) failed - check output above"
fi
