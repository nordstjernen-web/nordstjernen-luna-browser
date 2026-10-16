# _msys_env.sh: select the MSYS2 environment for the _msys_* scripts -- UCRT64, or MINGW64 where only that one has GTK 4 installed.
if [ ! -f /ucrt64/bin/libgtk-4-1.dll ] && [ -f /mingw64/bin/libgtk-4-1.dll ]; then
    export MSYSTEM=MINGW64
else
    export MSYSTEM=UCRT64
fi
export PATH="/${MSYSTEM,,}/bin:$PATH"
