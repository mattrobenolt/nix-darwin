#!/usr/bin/env bash
# Usage: sink-cycle.sh [next|prev|status]

get_sink_names() {
  pactl list short sinks | cut -f2
}

get_default() {
  pactl get-default-sink
}

get_friendly_name() {
  local sink="$1"
  pactl list sinks | grep -A 2 "Name:.*$sink" \
    | grep 'Description:' \
    | head -1 \
    | sed 's/.*Description: //'
}

cmd="${1:-status}"

if [[ "$cmd" == "status" ]]; then
  default=$(get_default)
  get_friendly_name "$default"
  exit 0
fi

mapfile -t sinks < <(get_sink_names)
[[ ${#sinks[@]} -lt 2 ]] && exit 0

default=$(get_default)
current_idx=0
for i in "${!sinks[@]}"; do
  [[ "${sinks[$i]}" == "$default" ]] && current_idx=$i && break
done

if [[ "$cmd" == "next" ]]; then
  next_idx=$(( (current_idx + 1) % ${#sinks[@]} ))
elif [[ "$cmd" == "prev" ]]; then
  next_idx=$(( (current_idx - 1 + ${#sinks[@]}) % ${#sinks[@]} ))
else
  exit 1
fi

pactl set-default-sink "${sinks[$next_idx]}"
