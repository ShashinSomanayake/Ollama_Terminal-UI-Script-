<div align="center">

<h1>🤖 AI Assistant + Android Tools for Termux</h1>

<p><b>All-in-One Bash Script for AI + Android Device Management</b></p>

<p>
<img src="https://img.shields.io/badge/License-MIT-yellow.svg">
<img src="https://img.shields.io/badge/language-bash-blue.svg">
<img src="https://img.shields.io/badge/platform-termux-green.svg">
</p>

</div>

<hr>

<h2>📝 GitHub Short Description (≈200 words)</h2>

<pre>
🤖 AI Assistant + Android Tools for Termux – All-in-One Bash Script

Unify your AI workflows and device management in a single terminal interface.  
This script combines:

- Ollama integration – Start/stop the server, choose from multiple models
  (Phi-4, Gemma, DeepSeek), run prompts, chat interactively,
  use voice input, and manage logs/templates.

- Android app & process control – Disable/enable/force-stop apps via ADB,
  monitor live CPU/RAM usage with an htop-like menu, kill processes,
  and clean up background hogs.

- Productivity tools – Daily journal, file summarizer,
  offline wiki lookup, REST API helper, and Modelfile management.

Everything is menu-driven with dialog – no typing required
for Android tasks.

Built for Termux, but works wherever Bash, ADB, and Ollama are available.

Perfect for developers, power users, and AI enthusiasts who want
a unified toolbox on their Android device.

No more switching between scripts – one script does it all.

🔗 [Repository link]
</pre>

<hr>

<h2>📚 README.md (Full Guide)</h2>

<h3>Overview</h3>

<p>
<b>One script to rule them all</b> – combines AI model interaction (Ollama)
with powerful Android device management (ADB) into a single,
menu-driven interface.
</p>

<p>
No more juggling multiple scripts; everything you need is in one place.
</p>

<hr>

<h2>✨ Features</h2>

<table>
<tr>
<td width="50%">

<h3>🧠 AI Assistant (Ollama)</h3>

<ul>
<li>Start / stop Ollama server with wake lock management</li>
<li>Choose from four popular models</li>
<ul>
<li>Phi-4 Mini</li>
<li>Gemma 1B / 4B</li>
<li>DeepSeek-R1 8B</li>
</ul>
<li>Write prompts</li>
<li>Chat interactively</li>
<li>Reuse old prompts</li>
<li>Voice input (Termux:API)</li>
<li>Log prompts and responses with tags</li>
<li>Manage Modelfiles and templates</li>
<li>View Ollama help</li>
</ul>

</td>

<td width="50%">

<h3>📱 Android Device Control (ADB)</h3>

<ul>
<li><b>App Manager</b></li>
<ul>
<li>List user apps</li>
<li>List system apps</li>
<li>List disabled apps</li>
<li>Force-stop apps</li>
<li>Disable apps</li>
<li>Enable apps</li>
</ul>

<li><b>Process Monitor</b></li>
<ul>
<li>Live CPU/RAM view (like htop)</li>
<li>Auto highlight heavy processes</li>
<li>Kill selected processes</li>
<li>Force-stop packages</li>
</ul>

<li>Fully menu-driven using <code>dialog</code></li>
<li>No typing required</li>

</ul>

</td>
</tr>
</table>

<hr>

<h2>🛠 Productivity Tools</h2>

<ul>
<li>Daily journal with automatic date-stamped file</li>
<li>File summarizer (pipe text files to AI)</li>
<li>Offline wiki lookup</li>
<li>REST API helper</li>
<li>GGUF model import guide</li>
</ul>

<hr>

<h2>📂 Organized Storage</h2>

<table>
<tr>
<th>Directory</th>
<th>Purpose</th>
</tr>

<tr>
<td><code>~/ollama_logs/</code></td>
<td>Prompt and response logs</td>
</tr>

<tr>
<td><code>~/ollama_modelfiles/</code></td>
<td>Custom Modelfiles</td>
</tr>

<tr>
<td><code>~/ollama_templates/</code></td>
<td>Prompt templates</td>
</tr>

</table>

<hr>

<h2>📋 Prerequisites</h2>

<ul>
<li><b>Termux</b> (from F-Droid or GitHub, <b>not Google Play</b>)</li>
<li>Android device with <b>Developer Options</b> enabled</li>
<li><b>Wireless Debugging</b> enabled for ADB</li>
</ul>

<h3>Required packages</h3>

<pre><code>
pkg install fzf dialog android-tools curl termux-api
</code></pre>

<h3>Ollama</h3>

<p>
Install from:
</p>

<p>
<a href="https://ollama.com">https://ollama.com</a>
</p>

<p>Optional: offline wiki tool such as <b>offline-wiki</b> or <b>kiwix</b>.</p>

<hr>

<h2>🚀 Installation</h2>

<h3>1 Clone repository</h3>

<pre><code>
git clone https://github.com/yourusername/ai-assistant-termux.git
cd ai-assistant-termux
</code></pre>

<h3>2 Make script executable</h3>

<pre><code>
chmod +x ai-assistant.sh
</code></pre>

<h3>3 Connect ADB (optional)</h3>

<pre><code>
adb pair IP:PORT
adb connect IP:PORT
</code></pre>

<h3>4 Run the script</h3>

<pre><code>
./ai-assistant.sh
</code></pre>

<hr>

<h2>🎮 Usage Guide</h2>

<p>When the script starts you will see the main menu:</p>

<pre>
==========================================
   AI ASSISTANT & ANDROID TOOLS
==========================================
1) Start Ollama Server
2) Stop Ollama Server
3) Launch AI Assistant (full interactive menu)
4) Android App Manager (disable/enable/force-stop)
5) Android Process Monitor (live CPU/RAM view)
6) Exit
</pre>

<hr>

<h3>Option 1 – Start Ollama Server</h3>

<ul>
<li>Checks if server is already running</li>
<li>If not, starts using <code>nohup</code></li>
<li>Acquires Termux wake lock</li>
<li>Saves PID to <code>~/.ollama_pid</code></li>
<li>Logs output to <code>~/ollama.log</code></li>
</ul>

<h3>Option 2 – Stop Ollama Server</h3>

<ul>
<li>Kills process using stored PID</li>
<li>Fallback: <code>pkill</code></li>
<li>Releases wake lock</li>
</ul>

<hr>

<h2>🧠 AI Assistant Submenu</h2>

<table>
<tr>
<th>#</th>
<th>Function</th>
<th>Description</th>
</tr>

<tr><td>1</td><td>New prompt</td><td>Write prompt in nano and run it</td></tr>
<tr><td>2</td><td>Direct chat</td><td>Interactive chat with model</td></tr>
<tr><td>3</td><td>Reuse prompt</td><td>Select old prompt using fzf</td></tr>
<tr><td>4</td><td>Voice input</td><td>Capture speech using Termux API</td></tr>
<tr><td>5</td><td>Manage logs</td><td>Browse logs with less</td></tr>
<tr><td>6</td><td>Modelfiles</td><td>Create/view/delete Modelfiles</td></tr>
<tr><td>7</td><td>GGUF help</td><td>Instructions for GGUF models</td></tr>
<tr><td>8</td><td>REST API</td><td>Shows example curl request</td></tr>
<tr><td>9</td><td>Model management</td><td>ollama list / ps / stop / rm</td></tr>
<tr><td>10</td><td>Help</td><td>ollama run help</td></tr>
<tr><td>11</td><td>Templates</td><td>Manage prompt templates</td></tr>
<tr><td>12</td><td>Daily journal</td><td>Create dated journal file</td></tr>
<tr><td>13</td><td>Offline wiki</td><td>Search offline wiki</td></tr>
<tr><td>14</td><td>File summarizer</td><td>Summarize any text file</td></tr>
<tr><td>15</td><td>ADB cleanup</td><td>Run App Manager + Process Monitor</td></tr>
<tr><td>0</td><td>Return</td><td>Back to main menu</td></tr>

</table>

<hr>

<h2>📱 Android App Manager</h2>

<ul>
<li>Lists user, system, and disabled apps</li>
<li>Select multiple apps</li>
<li>Actions available:</li>
<ul>
<li>Force Stop</li>
<li>Disable</li>
<li>Enable</li>
</ul>
<li>Confirmation before execution</li>
<li>Results displayed in message box</li>
</ul>

<hr>

<h2>📊 Android Process Monitor</h2>

<ul>
<li>Shows top 50 processes</li>
<li>Displays CPU and RAM usage</li>
<li>Processes over 10% usage auto-selected</li>
<li>Choose to kill process or force-stop package</li>
<li>Refresh loop continues until canceled</li>
</ul>

<hr>

<h2>🔧 Configuration</h2>

<h3>Directories</h3>

<ul>
<li><code>~/ollama_logs/</code></li>
<li><code>~/ollama_modelfiles/</code></li>
<li><code>~/ollama_templates/</code></li>
</ul>

<p>Paths can be changed by editing variables at the top of the script.</p>

<h3>Extra flags for <code>ollama run</code></h3>

<ul>
<li><code>--nowordwrap</code> – disable word wrapping</li>
<li><code>--keepalive</code> – keep model loaded</li>
</ul>

<hr>

<h2>🧠 How It Works</h2>

<p>The script is a single Bash file with modular functions:</p>

<ul>
<li><b>check_dependencies</b> – verify required commands</li>
<li><b>start_ollama_server</b> – start Ollama daemon</li>
<li><b>stop_ollama_server</b> – stop daemon</li>
<li><b>app_manager</b> – Android app control</li>
<li><b>process_manager</b> – Android process monitor</li>
<li><b>ai_assistant_submenu</b> – AI interaction menu</li>
<li><b>main_menu</b> – top level navigation</li>
</ul>

<p>
Temporary files are cleaned using <code>trap</code>.
</p>

<hr>

<h2>⚠️ Troubleshooting</h2>

<table>
<tr>
<th>Problem</th>
<th>Solution</th>
</tr>

<tr>
<td>adb command not found</td>
<td>pkg install android-tools</td>
</tr>

<tr>
<td>ADB not connected</td>
<td>Run adb devices and reconnect</td>
</tr>

<tr>
<td>dialog errors</td>
<td>pkg install dialog</td>
</tr>

<tr>
<td>Ollama server fails</td>
<td>Check ~/ollama.log</td>
</tr>

<tr>
<td>Voice input fails</td>
<td>Install Termux API</td>
</tr>

<tr>
<td>fzf missing</td>
<td>pkg install fzf</td>
</tr>

<tr>
<td>offline-wiki missing</td>
<td>Install kiwix or another wiki tool</td>
</tr>

</table>

<hr>

<h2>🤝 Contributing</h2>

<p>
Contributions are welcome.
</p>

<ul>
<li>Bug fixes</li>
<li>New features</li>
<li>Additional ADB tools</li>
<li>Better Android compatibility</li>
<li>Documentation improvements</li>
</ul>

<hr>

<h2>📄 License</h2>

<p>
This project is licensed under the MIT License.
</p>

<hr>

<h2>🙏 Acknowledgements</h2>

<ul>
<li><a href="https://ollama.com">Ollama</a></li>
<li>Termux community</li>
<li>Original script authors</li>
</ul>

<hr>

<div align="center">

<b>Enjoy your unified AI + Android toolbox! 🚀</b>

</div>
