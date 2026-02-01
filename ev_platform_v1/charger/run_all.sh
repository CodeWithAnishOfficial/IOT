#!/bin/bash

echo "Starting all devices..."
echo "------------------------"

PIDS=()

for file in ./dev*; do
    if [[ -x "$file" && -f "$file" ]]; then
        name=$(basename "$file")
        echo "Launching $file"
        stdbuf -oL -eL "$file" 2>&1 | sed "s/^/[$name] /" &
        PIDS+=($!)
    fi
done

echo "------------------------"
echo "All programs running. Press CTRL+C to stop."

trap "echo 'Stopping all...'; kill ${PIDS[*]}; exit" SIGINT

wait
