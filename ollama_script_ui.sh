#!/data/data/com.termux/files/usr/bin/bash

# =============================================================================
#  Unified AI Assistant & Android Tools for Termux
#  Combines: ollama-ai.sh, ollama-launch-adv.sh, start-ollama.sh,
#            stop-ollama.sh, app_manager.sh, process_manager.sh
# =============================================================================

# ----------------------------- Configuration ---------------------------------
# Directories (all under $HOME)
LOGS_DIR="$HOME/ollama_logs"
MODELFILES_DIR="$HOME/ollama_modelfiles"
TEMPLATES_DIR="$HOME/ollama_templates"
PID_FILE="$HOME/.ollama_pid"

# Global variables (used in AI submenu)
MODEL=""          # e.g. "phi4-mini"
MODEL_TAG=""      # human‑readable tag for logging, e.g. "Phi4Mini"
EXTRA_FLAGS=""    # e.g. "--nowordwrap --keepalive"

# Create required directories (if missing)
mkdir -p "$LOGS_DIR" "$MODELFILES_DIR" "$TEMPLATES_DIR"

# --------------------------- Helper Functions --------------------------------

# Check for essential commands; exit if critical ones are missing.
check_dependencies() {
    local missing=()
    for cmd in ollama fzf dialog adb curl pgrep pkill nohup termux-wake-lock termux-wake-unlock termux-tts-speak termux-speech-to-text; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            # Some are optional – we'll just warn later
            case "$cmd" in
                termux-tts-speak|termux-speech-to-text|offline-wiki)
                    # optional, ignore here
                    ;;
                *)
                    missing+=("$cmd")
                    ;;
            esac
        fi
    done
    if [ ${#missing[@]} -gt 0 ]; then
        echo "❌ Missing required commands: ${missing[*]}"
        echo "Install them with: pkg install ${missing[*]}"
        exit 1
    fi
}

# Check if ADB is connected (device state)
check_adb_connected() {
    adb get-state 2>/dev/null | grep -q "device"
}

# Check if Ollama server is already running (via pgrep or curl)
is_ollama_running() {
    if pgrep -f "ollama serve" >/dev/null; then
        return 0
    fi
    # Also try a curl check (in case pgrep fails)
    if curl -s http://localhost:11434 >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

# Start Ollama server (with wake lock, nohup, save PID)
start_ollama_server() {
    echo "🔍 Starting Ollama server..."
    if is_ollama_running; then
        echo "✅ Ollama is already running."
        return 0
    fi
    # Acquire wake lock (if available)
    if command -v termux-wake-lock >/dev/null; then
        termux-wake-lock
    fi
    nohup ollama serve > "$HOME/ollama.log" 2>&1 &
    echo $! > "$PID_FILE"
    echo "⏳ Waiting for server to be ready..."
    sleep 3
    if is_ollama_running; then
        echo "✅ Ollama started (PID $(cat "$PID_FILE")). Logs: $HOME/ollama.log"
    else
        echo "❌ Failed to start Ollama. Check $HOME/ollama.log"
        return 1
    fi
}

# Stop Ollama server (kill process, release wake lock)
stop_ollama_server() {
    echo "🛑 Stopping Ollama server..."
    if [ -f "$PID_FILE" ]; then
        kill "$(cat "$PID_FILE")" 2>/dev/null && echo "Process killed."
        rm -f "$PID_FILE"
    else
        pkill -f "ollama serve" && echo "Process killed (pkill)."
    fi
    # Release wake lock
    if command -v termux-wake-unlock >/dev/null; then
        termux-wake-unlock
    fi
    echo "✅ Server stopped, wake lock released."
}

# Interactive model selection (sets MODEL and MODEL_TAG)
select_model() {
    echo
    echo "🤖 Select an AI model:"
    echo "1) Phi 4 Mini       (3.8B) – Reasoning-focused"
    echo "2) Gemma 3          (1B)   – Ultra-lightweight"
    echo "3) Gemma 3          (4B)   – Balanced general"
    echo "4) DeepSeek-R1      (8B)   – Best for code/tasks"
    read -p "Choose [1–4]: " model_choice
    case "$model_choice" in
        1) MODEL="phi4-mini"; MODEL_TAG="Phi4Mini" ;;
        2) MODEL="gemma3:1b"; MODEL_TAG="Gemma1B" ;;
        3) MODEL="gemma3:4b"; MODEL_TAG="Gemma4B" ;;
        4) MODEL="deepseek-r1:8b"; MODEL_TAG="DeepSeekR1" ;;
        *) echo "Invalid choice."; return 1 ;;
    esac
    echo "✅ Model set to $MODEL"
}

# Collect advanced flags (--nowordwrap, --keepalive) – modifies EXTRA_FLAGS
collect_extra_flags() {
    EXTRA_FLAGS=""
    read -p "🧩 Add --nowordwrap? [y/N]: " nowrap
    [[ "$nowrap" =~ ^[Yy]$ ]] && EXTRA_FLAGS+=" --nowordwrap"
    read -p "🧩 Add --keepalive? [y/N]: " keep
    [[ "$keep" =~ ^[Yy]$ ]] && EXTRA_FLAGS+=" --keepalive"
}

# Ensure Ollama server is running; if not, offer to start it.
ensure_server_running() {
    if ! is_ollama_running; then
        echo "⚠️ Ollama server is not running."
        read -p "Start it now? [Y/n]: " ans
        if [[ ! "$ans" =~ ^[Nn]$ ]]; then
            start_ollama_server || return 1
        else
            echo "Cannot proceed without server. Returning to menu."
            return 1
        fi
    fi
    return 0
}

# Log a prompt and its response (used in option 1)
log_prompt_response() {
    local prompt_text="$1"
    local response_text="$2"
    local user_tag="$3"
    local timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
    local tagname="${MODEL_TAG}_${user_tag:-untagged}_$timestamp"
    echo "$prompt_text" > "$LOGS_DIR/$tagname.txt"
    echo "$response_text" > "$LOGS_DIR/${tagname}_response.txt"
    echo "📝 Logged as $tagname"
}

# ------------------------ Android App Manager (from app_manager.sh) ---------
app_manager() {
    # Temporary files
    local MENU_TMP=$(mktemp)
    local CHOICE_TMP=$(mktemp)
    local CONFIRM_TMP=$(mktemp)

    # Cleanup on function exit
    trap "rm -f '$MENU_TMP' '$CHOICE_TMP' '$CONFIRM_TMP'" RETURN

    dialog --title "Android App Manager" --msgbox \
"Welcome!

This tool lets you manage Android apps using Wireless ADB.

You can:
- View installed apps
- Choose which ones to manage
- Disable, enable, or force stop them

No typing needed – everything is menu-driven.
Tap OK to continue." 14 60

    if ! check_adb_connected; then
        dialog --title "ADB Not Connected" --msgbox \
"ADB is not connected.

To fix:
1. Enable Developer Options on your Android device.
2. Turn on Wireless Debugging.
3. Connect from Termux using:
   adb pair IP:PORT
   adb connect IP:PORT

Then re-run this tool." 14 60
        return 1
    fi

    dialog --infobox "Reading app data from your device..." 5 50
    local user_pkgs=$(adb shell pm list packages -3 | cut -d ":" -f2 | tr -d '\r')
    local system_pkgs=$(adb shell pm list packages -s | cut -d ":" -f2 | tr -d '\r')
    local disabled_pkgs=$(adb shell pm list packages -d | cut -d ":" -f2 | tr -d '\r')

    dialog --title "App Type" --menu "Which type of apps do you want to manage?" 15 50 4 \
        1 "User Installed Apps (downloaded apps)" \
        2 "System Apps (preinstalled or OS apps)" \
        3 "Disabled Apps (currently turned off)" \
        2>"$CHOICE_TMP"

    local choice=$(cat "$CHOICE_TMP")
    local pkgs category
    case "$choice" in
        1) pkgs=$user_pkgs; category="User Installed" ;;
        2) pkgs=$system_pkgs; category="System" ;;
        3) pkgs=$disabled_pkgs; category="Disabled" ;;
        *) dialog --msgbox "No selection made." 10 40; return 1 ;;
    esac

    > "$MENU_TMP"
    dialog --infobox "Preparing app list..." 5 40
    for pkg in $pkgs; do
        local label=$(adb shell dumpsys package "$pkg" | grep -m 1 "label=" | sed 's/.*label=//;s/\r//')
        [ -z "$label" ] && label="$pkg"
        echo "$pkg" "\"$label\"" off >> "$MENU_TMP"
    done

    dialog --checklist "Select apps to manage from the '$category' group:" 20 70 15 --file "$MENU_TMP" 2>"$CHOICE_TMP"
    local selected=$(cat "$CHOICE_TMP")
    if [ -z "$selected" ]; then
        dialog --msgbox "No apps selected. Exiting." 10 40
        return 0
    fi

    dialog --menu "What do you want to do with the selected apps?" 15 50 4 \
        1 "Force Stop (close the app immediately)" \
        2 "Disable (prevent app from launching)" \
        3 "Enable (turn app back on)" \
        2>"$CHOICE_TMP"
    local action=$(cat "$CHOICE_TMP")
    if [ -z "$action" ]; then
        dialog --msgbox "No action selected. Exiting." 10 40
        return 0
    fi

    local human_action=""
    case "$action" in
        1) human_action="Force Stop" ;;
        2) human_action="Disable" ;;
        3) human_action="Enable" ;;
    esac

    dialog --yesno "Are you sure you want to:\n\n$human_action the selected apps?\n\nProceed?" 12 50
    if [ $? -ne 0 ]; then
        dialog --msgbox "Cancelled by user." 10 40
        return 0
    fi

    local output=""
    IFS=" " read -r -a pkg_array <<< "$selected"
    for pkg in "${pkg_array[@]}"; do
        pkg=${pkg//\"/}
        local label=$(adb shell dumpsys package "$pkg" | grep -m 1 "label=" | sed 's/.*label=//;s/\r//')
        [ -z "$label" ] && label="$pkg"
        case "$action" in
            1) adb shell am force-stop "$pkg" && output+="$label → Force Stopped\n" ;;
            2) adb shell pm disable-user "$pkg" && output+="$label → Disabled\n" ;;
            3) adb shell pm enable "$pkg" && output+="$label → Enabled\n" ;;
        esac
    done

    dialog --title "Action Completed" --msgbox "Here's what was done:\n\n$output" 20 60
}

# ------------------------ Android Process Monitor (from process_manager.sh) -
process_manager() {
    local MENU_TMP=$(mktemp)
    local CHOICE_TMP=$(mktemp)
    local INFO_TMP=$(mktemp)

    trap "rm -f '$MENU_TMP' '$CHOICE_TMP' '$INFO_TMP'" RETURN

    dialog --title "Android Resource Monitor" --msgbox \
"Welcome to your live Android Process Manager!

You can:
- Monitor CPU/RAM like 'htop'
- Auto-detect background hogs
- Kill or force stop apps/services

No typing needed. Tap OK to begin." 14 60

    if ! check_adb_connected; then
        dialog --msgbox "ADB is not connected. Connect via Wireless Debugging." 10 50
        return 1
    fi

    while true; do
        adb shell top -n 1 -m 50 | grep -E "^[ ]*[0-9]+" > "$INFO_TMP"

        > "$MENU_TMP"
        while read -r line; do
            local pid=$(echo "$line" | awk '{print $1}')
            local cpu=$(echo "$line" | awk '{print $9}' | cut -d'%' -f1)
            local mem=$(echo "$line" | awk '{print $10}' | cut -d'%' -f1)
            local pname=$(echo "$line" | awk '{print $NF}')

            local label=$(adb shell dumpsys package "$pname" 2>/dev/null | grep -m 1 "label=" | sed 's/.*label=//;s/\r//')
            [ -z "$label" ] && label="$pname"

            local checked=off
            if [[ "$cpu" -gt 10 || "$mem" -gt 10 ]]; then
                label="$label (CPU: ${cpu}%, RAM: ${mem}%) [HIGH USAGE]"
                checked=on
            else
                label="$label (CPU: ${cpu}%, RAM: ${mem}%)"
            fi

            echo "$pid" "\"$label\"" "$checked" >> "$MENU_TMP"
        done < "$INFO_TMP"

        dialog --checklist \
"Live CPU/RAM View (Top 50):

[HIGH USAGE] processes are auto-selected.
Tap OK to manage them or REFRESH to update stats.

Press Cancel to exit." \
20 70 15 --file "$MENU_TMP" 2>"$CHOICE_TMP"

        local ret=$?
        local selection=$(cat "$CHOICE_TMP")

        if [ $ret -eq 1 ]; then
            dialog --yesno "Exit the live monitor?" 7 40 && break
            continue
        elif [ $ret -ne 0 ]; then
            continue
        fi

        dialog --menu "What do you want to do with selected processes?" 15 50 3 \
            1 "Kill (terminate by PID)" \
            2 "Force-stop (only if it's an app)" \
            3 "Cancel and return" \
            2>"$CHOICE_TMP"
        local action=$(cat "$CHOICE_TMP")

        if [[ "$action" == "3" || -z "$action" ]]; then
            continue
        fi

        dialog --yesno "Are you sure you want to apply this action to selected processes?" 8 50
        [ $? -ne 0 ] && continue

        local output=""
        IFS=" " read -r -a items <<< "$selection"
        for pid in "${items[@]}"; do
            pid="${pid//\"/}"
            local pname=$(adb shell ps -A | grep " $pid " | awk '{print $NF}' | tr -d '\r')
            if [ "$action" = "1" ]; then
                adb shell kill "$pid" && output+="PID $pid ($pname): KILLED\n"
            elif [ "$action" = "2" ]; then
                adb shell am force-stop "$pname" && output+="Package $pname: FORCE-STOPPED\n"
            fi
        done

        dialog --title "Actions Complete" --msgbox "$output" 20 60
    done
}

# ------------------------ AI Assistant Submenu ------------------------------
ai_assistant_submenu() {
    # If no model selected yet, ask now
    if [ -z "$MODEL" ]; then
        select_model || return
        collect_extra_flags
    fi

    # Ensure server is running
    ensure_server_running || return

    while true; do
        echo
        echo "📋 AI Assistant (model: $MODEL, flags: $EXTRA_FLAGS)"
        echo "1) Write a new prompt (nano)"
        echo "2) Direct chat (shell)"
        echo "3) Reuse old prompt (fzf)"
        echo "4) Voice input (Termux)"
        echo "5) Manage logs/history"
        echo "6) Manage Modelfiles"
        echo "7) GGUF Import Help"
        echo "8) REST API Help"
        echo "9) Ollama model management"
        echo "10) Ollama help commands"
        echo "11) Prompt template manager"
        echo "12) Daily Journal Mode"
        echo "13) Offline Wiki Lookup"
        echo "14) AI File Summarizer"
        echo "15) Run ADB cleanup tools (app + process manager)"
        echo "0) Return to main menu"
        read -p "Choose [0–15]: " mode

        case "$mode" in
            1)
                echo "📝 Enter your prompt (nano will open)..."
                local prompt_file=$(mktemp)
                nano "$prompt_file"
                local prompt=$(cat "$prompt_file")
                rm -f "$prompt_file"
                read -p "🏷 Add tag (or empty): " user_tag
                local timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
                local tagname="${MODEL_TAG}_${user_tag:-untagged}_$timestamp"
                echo "$prompt" > "$LOGS_DIR/$tagname.txt"
                ollama run "$MODEL" $EXTRA_FLAGS < "$LOGS_DIR/$tagname.txt" | tee "$LOGS_DIR/${tagname}_response.txt"
                ;;
            2)
                echo "💬 Interactive shell. Ctrl+C to exit."
                ollama run "$MODEL" $EXTRA_FLAGS
                ;;
            3)
                local selected=$(find "$LOGS_DIR" -type f -name "*.txt" ! -name "*_response.txt" | fzf --preview "cat {}")
                if [ -n "$selected" ]; then
                    ollama run "$MODEL" $EXTRA_FLAGS < "$selected"
                fi
                ;;
            4)
                if ! command -v termux-speech-to-text >/dev/null; then
                    echo "❌ termux-speech-to-text not installed. Install Termux:API and run 'pkg install termux-api'."
                    continue
                fi
                echo "🎤 Speak after beep..."
                termux-tts-speak "Speak now."
                local voice_file=$(mktemp)
                termux-speech-to-text > "$voice_file"
                cat "$voice_file"
                ollama run "$MODEL" $EXTRA_FLAGS < "$voice_file"
                rm -f "$voice_file"
                ;;
            5)
                echo "🧾 Log viewer (select a file to view):"
                local logfile=$(find "$LOGS_DIR" -type f | fzf --preview "cat {}")
                if [ -n "$logfile" ]; then
                    less "$logfile"
                fi
                ;;
            6)
                echo "🛠 Modelfile manager:"
                echo "1) View existing"
                echo "2) Create new"
                echo "3) Delete one"
                read -p "Choose [1–3]: " mm
                case "$mm" in
                    1) ls "$MODELFILES_DIR" ;;
                    2) read -p "Name: " mname; nano "$MODELFILES_DIR/$mname.Modelfile" ;;
                    3) ls "$MODELFILES_DIR"; read -p "Name to delete: " del; rm -f "$MODELFILES_DIR/$del.Modelfile" ;;
                esac
                ;;
            7)
                echo "📦 GGUF Import Help:"
                echo "1. Download .gguf model"
                echo "2. Place in ~/models"
                echo "3. Use with llama.cpp or LocalAI config"
                read -p "Press Enter to continue"
                ;;
            8)
                echo "🔗 REST API Helper:"
                echo "curl http://localhost:11434/api/generate -d '{\"model\":\"$MODEL\",\"prompt\":\"Hello\"}'"
                read -p "Press Enter to continue"
                ;;
            9)
                echo "📦 Ollama Model Manager:"
                echo "1) list"
                echo "2) ps"
                echo "3) stop"
                echo "4) rm"
                read -p "Choose [1–4]: " om
                case "$om" in
                    1) ollama list ;;
                    2) ollama ps ;;
                    3) read -p "Model name: " mn; ollama stop "$mn" ;;
                    4) read -p "Model name: " mn; ollama rm "$mn" ;;
                esac
                read -p "Press Enter to continue"
                ;;
            10)
                ollama run --help | less
                ;;
            11)
                echo "📋 Prompt Template Manager:"
                echo "1) Add new"
                echo "2) View all"
                echo "3) Delete one"
                read -p "Choose [1–3]: " pt
                case "$pt" in
                    1) read -p "Template name: " tname; nano "$TEMPLATES_DIR/$tname.txt" ;;
                    2) ls "$TEMPLATES_DIR"; read -p "View which? " vname; cat "$TEMPLATES_DIR/$vname.txt"; read -p "Press Enter" ;;
                    3) ls "$TEMPLATES_DIR"; read -p "Delete which? " dname; rm -f "$TEMPLATES_DIR/$dname.txt" ;;
                esac
                ;;
            12)
                echo "📓 Daily Journal Mode"
                local journal_file="$HOME/journal-$(date +%F).txt"
                nano "$journal_file"
                echo "Journal saved to $journal_file"
                ;;
            13)
                if ! command -v offline-wiki >/dev/null; then
                    echo "❌ offline-wiki not installed. Please install it separately."
                    read -p "Press Enter"
                    continue
                fi
                read -p "Search topic: " wq
                offline-wiki "$wq"
                read -p "Press Enter"
                ;;
            14)
                echo "📄 AI File Summarizer"
                read -p "File to summarize: " fsum
                if [ -f "$fsum" ]; then
                    cat "$fsum" | ollama run "$MODEL" $EXTRA_FLAGS
                else
                    echo "File not found."
                fi
                read -p "Press Enter"
                ;;
            15)
                echo "🧹 Running ADB cleanup tools..."
                if check_adb_connected; then
                    app_manager
                    process_manager
                else
                    echo "⚠️ ADB not connected. Skipping."
                fi
                read -p "Press Enter"
                ;;
            0)
                break
                ;;
            *)
                echo "❌ Invalid option."
                ;;
        esac
    done
}

# ----------------------------- Main Menu -------------------------------------
main_menu() {
    while true; do
        clear
        echo "=========================================="
        echo "   AI ASSISTANT & ANDROID TOOLS"
        echo "=========================================="
        echo "1) Start Ollama Server"
        echo "2) Stop Ollama Server"
        echo "3) Launch AI Assistant (full interactive menu)"
        echo "4) Android App Manager (disable/enable/force-stop)"
        echo "5) Android Process Monitor (live CPU/RAM view)"
        echo "6) Exit"
        read -p "Choose [1–6]: " main_choice

        case "$main_choice" in
            1) start_ollama_server ; read -p "Press Enter" ;;
            2) stop_ollama_server ; read -p "Press Enter" ;;
            3) ai_assistant_submenu ;;
            4) app_manager ;;
            5) process_manager ;;
            6) echo "👋 Exiting. Have a great day!"; exit 0 ;;
            *) echo "Invalid option." ; sleep 1 ;;
        esac
    done
}

# ----------------------------- Entry Point -----------------------------------
check_dependencies
main_menu