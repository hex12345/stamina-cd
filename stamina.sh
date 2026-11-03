_STAMINA_FILE="$HOME/.cd_stamina"
_STAMINA_MAX=100

_stamina_get() { cat "$_STAMINA_FILE" 2>/dev/null || echo "$_STAMINA_MAX"; }
_stamina_set() { echo "$1" > "$_STAMINA_FILE"; }

_stamina_bar() {
    local s=$1 n=$(( $1 / 10 )) bar="" i
    for ((i=0;i<10;i++)); do (( i < n )) && bar+="█" || bar+="░"; done
    local col="\033[92m"; (( s < 50 )) && col="\033[93m"; (( s < 20 )) && col="\033[91m"
    echo -e "${col}stamina [${bar}] ${s}/${_STAMINA_MAX}\033[0m"
}

cd() {
    local s cost target="${1:-$HOME}" depth
    s=$(_stamina_get)
    # deeper paths and going up cost more
    depth=$(tr -cd '/' <<< "$target" | wc -c)
    cost=$(( 5 + depth * 3 ))
    [[ "$target" == ".."* ]] && cost=$(( cost + 8 ))
    [[ "$target" == "/" ]] && cost=25
    [[ "$target" == "~" || -z "$1" ]] && cost=2

    if (( s < cost )); then
        echo -e "\033[91m*collapses on the floor* i can't walk to ${target}... carry me... (run 'sleep' or 'eat')\033[0m"
        _stamina_bar "$s"
        return 1
    fi
    builtin cd "$@" || { echo "*walked into a wall* that path doesn't exist. -2 stamina for the bruise"; _stamina_set $(( s - 2 )); return 1; }
    s=$(( s - cost ))
    _stamina_set "$s"
    case $(( RANDOM % 6 )) in
        0) echo "*huff* *puff* made it." ;;
        1) (( depth > 3 )) && echo "that was a LOT of stairs." ;;
        2) (( s < 30 )) && echo "my legs... i need a break..." ;;
    esac
    (( s < 40 )) && _stamina_bar "$s"
    true
}

sleep() {
    if [[ $# -gt 0 && "$1" =~ ^[0-9.]+[smhd]?$ ]]; then
        command sleep "$@"
        local cur; cur=$(_stamina_get)
        _stamina_set $(( cur + 30 > _STAMINA_MAX ? _STAMINA_MAX : cur + 30 ))
        echo "*yawns* refreshed. +30 stamina"
    else
        echo "zzz..."; command sleep 3
        _stamina_set "$_STAMINA_MAX"
        echo "*wakes up* fully rested! ready to cd!"
    fi
    _stamina_bar "$(_stamina_get)"
}

eat() {
    local cur foods=("a protein bar" "uranus" "a whole pizza" "cereal" "2 monitors")
    cur=$(_stamina_get)
    _stamina_set $(( cur + 20 > _STAMINA_MAX ? _STAMINA_MAX : cur + 20 ))
    echo "*eats ${foods[RANDOM % ${#foods[@]}]}* +20 stamina"
    _stamina_bar "$(_stamina_get)"
}

stamina() { _stamina_bar "$(_stamina_get)"; }
