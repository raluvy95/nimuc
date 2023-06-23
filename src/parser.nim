import os
import std/parseopt
import strutils

const help = """
nimuc - a Nim variant of original muc

--help, -h              -> Shows this help page
--version, -v           -> Shows version

--count, -c <int>       -> Limit count of commands displayed, defaults to 10
--count_sudo, -C <bool> -> Also counts sudo/doas, defaults to false

--bar, -b <char>        -> Set bar's fill char, defaults to ▮
--bar_empty, -be <char> -> Set bar's empty char, defaults to (empty space)
--bar_open, -bo <char>  -> Set bar's open char, defaults to [
--bar_close, -bc <char> -> Set bar's close char, defaults to ]
"""

const version = """
version 0.1.0
"""

type
    ArgParser* = ref object
        version*: bool
        count*: int
        bar*: string
        bar_empty*: string
        bar_open*: string
        bar_close*: string
        count_sudo*: bool
        file*: string

proc newArgParser(): ArgParser =
    ArgParser(count: 10, bar: "▮", bar_empty: " ",
            bar_open: "[", bar_close: "]", count_sudo: false)

proc getParse*(): ArgParser =
    var argsDict: ArgParser = newArgParser()
    for kind, key, val in getopt(commandLineParams()):
        case kind
            of cmdEnd: discard
            of cmdArgument:
                argsDict.file = key
            of cmdLongOption, cmdShortOption:
                case key
                    of "help", "h": 
                        echo help
                        quit()
                    of "version", "v": 
                        echo version
                        quit()
                    of "count", "c":
                        argsDict.count = val.parseInt()
                        break
                    of "bar", "b":
                        argsDict.bar = val
                        break
                    of "bar_empty", "be":
                        argsDict.bar_empty = val
                        break
                    of "bar_open", "bo":
                        argsDict.bar_open = val
                        break
                    of "bar_close", "bc":
                        argsDict.bar_close = val
                        break
                    of "count_sudo", "C":
                        argsDict.count_sudo = val.parseBool()
                        break
                    else:
                        echo help
                        quit()
    if not fileExists(argsDict.file):
        echo "The history file is not found."
        quit(1)
    return argsDict