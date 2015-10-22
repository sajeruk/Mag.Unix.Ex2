#!/usr/bin/env bash

usage () {
    local fnmsg="    FILENAME     --name of file to apply operation"
    local cmdmsg="    -c/--cmd     --name of command (default: echo)"
    local inputmsg="    -i/--input   --read lines from stdin"
    local helpmsg="    -h/--help    --this message"
    printf "Usage: $0 [FILENAME] [-c/--cmd echo] [-i/--input] [-h/--help]\
        \n%s\n%s\n%s\n%s\n" "$fnmsg" "$cmdmsg" "$inputmsg" "$helpmsg"
}

parse_args () {
    while [ "$#" -ge 1 ]
    do
        local key="$1"
        if [ "$key" = "-c" ] || [ "$key" = "--cmd" ]; then
            if [ -z "$cmd" ]; then
                cmd="$2"
                shift 2
            else
                return 1
            fi
        elif [ "$key" = "-i" ] || [ "$key" = "--input" ]; then
            if [ -z "$input" ]; then
                input="1"
                shift 1
            else
                return 1
            fi
        elif [ "$key" = "-h" ] || [ "$key" = "--help" ]; then
            usage
            exit 0
        elif [ -z "$filename" ]; then
            filename="$key"
            shift 1
        else
            return 1
        fi
    done

    if [ -n "$filename" ] && [ -n "$input" ]; then
        echo "Incorrect usage: cannot provide FILENAME and --input option at the same time" 1>&2
        return 2
    fi

    if [ -z "$filename" ] && [ -z "$input" ]; then
        echo "Incorrect usage: must provide FILENAME or --input option" 1>&2
        return 3
    fi

    filename=${filename:-/dev/stdin}
    cmd=${cmd:-echo}
    return 0
}

parse_args "$@"
if [ "$?" -ne 0 ]; then
    usage 1>&2
    exit 1
fi

if [ -z "$input" ] && ! [ -f "$filename" ]; then
    echo "No such file: $filename" 1>&2
    exit 1
fi

while IFS='' read -r line || [ -n "$line" ]; do
    "$cmd" "$line"
done < "$filename"
