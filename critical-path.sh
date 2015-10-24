#!/usr/bin/env bash

usage() {
    printf "Usage: $0 [options]\nOptions:\n\
        %s\t%s\n" "-h, --help" "Print this message and exit."
}

join() {
    local IFS="$1"; shift; echo "$*";
}

val() {
    if [[ "${TotalJobLength["$1"]}" = '' ]]; then
        local deps=( ${Dependencies["$1"]} )
        local maxVal="$(val "${deps[0]}")"
        local restDeps=( ${deps[@]:1} )
        for dep in "${restDeps[@]}"
        do
            local tmpVal="$(val "$dep")"
            maxVal="$(max "$maxVal" "$tmpVal")"
        done
        TotalJobLength["$1"]=$(( JobLength["$1"] + maxVal ))
    fi

    echo "${TotalJobLength["$1"]}"
}

max() {
    if [[ "$1" < "$2" ]]; then
        echo "$2"
    else
        echo "$1"
    fi
}

save_line() {
    local IFS=' '
    local linearray=( $1 )
    JobLength["${linearray[0]}"]="${linearray[1]}"
    MakeFile="$MakeFile${linearray[0]}: "
    local deps=( "${linearray[@]:2}" )
    local depsStr="$(join ' ' "${deps[@]}")"
    MakeFile="$MakeFile$depsStr\n\t:\n"
    Dependencies["${linearray[0]}"]="$depsStr"
    if [[ "$depsStr" = '' ]]; then
        TotalJobLength["${linearray[0]}"]="${linearray[1]}"
    fi
}

declare -A JobLength
declare -A Dependencies
declare -A TotalJobLength

if [ "$#" -ge 2 ]; then
    echo "Too many arguments" 2>&1
    usage 2>&1
    exit 1
fi

case "$1" in
    -h|--help)
        usage
        exit 0
        ;;
    '' )
        ;;
    * )
        echo "Wrong argument provided: $1" 2>&1
        usage 2>&1
        exit 1
esac


MakeFile="all: job\n\t:\n"
while IFS='' read -r line || [ -n "$line" ]; do
    save_line "$line"
done <&0

if echo -e "$MakeFile" | make -f - -s 2>&1 | grep -q "Circular.*dependency dropped"; then
    echo "Cyclic dependency" 2>&1
    exit 1
fi

echo "$(val job)"
