import parser
import strutils
import algorithm
import strformat
import pylib
import std/terminal

proc list_of_commands(arg: ArgParser): seq[string] =
    var commands: seq[string]
    for line in lines(arg.file):
        # zsh history
        if line.startsWith(": "):
            try:
                let splitted = line.split(" ")
                let command = splitted[1].split(";")
                if command[1] == "sudo" or command[1] == "doas":
                    commands.add(splitted[2])
                    if arg.count_sudo:
                        commands.add(command[1])
                else:
                    commands.add(command[1])
            except ValueError:
                continue
        else:
            let command = line.split(" ")
            if command[0] == "sudo" or command[0] == "doas":
                commands.add(command[1])
                if arg.count_sudo:
                    commands.add(command[0])
            else:
                commands.add(command[0])
    result = commands

type
    UsedCommand = ref object
        name: string
        count: int

func count_used(cmds: seq[string]): seq[UsedCommand] =
    var used: seq[UsedCommand]
    for cmd in cmds:
        var exists: bool = false
        for exist in used:
            if exist.name == cmd:
                exist.count += 1
                exists = true
        if not exists:
            used.add(UsedCommand(name: cmd, count: 1))
    result = used

func progress_bar(total: int, used: int, args: ArgParser): string =
    let fill = args.bar
    let empty = args.bar_empty
    let fill_number = (used / total) * 10
    let empty_number = 10 - fill_number.toInt()
    const colors = [fgBlue, fgBlue, fgBlue, fgGreen, fgGreen, fgGreen, fgYellow, fgYellow, fgYellow, fgRed]
    var str = args.bar_open
    for i in 0..<fill_number.toInt():
        str.add ansiForegroundColorCode(colors[i])
        str.add fill
        str.add ansiResetCode
    if empty_number > 0:
        str.add(empty.repeat(empty_number))
    str.add args.bar_close
    result = str

proc print_commands(count_used: seq[UsedCommand], total_cmds: seq[string], arg: ArgParser): void = 
    let total_cmds_count = total_cmds.len()
    let formatted_number = ($total_cmds_count).insertSep(',')
    echo f"{formatted_number} commands listed"

    proc customSort(x: UsedCommand, y: UsedCommand): int =
        cmp(x.count, y.count)
    let sort_cmd = sorted(count_used, customSort, Descending)
    var remaining: int = 0
    var highest_sort_usage_list: seq[int]
    var sort_cmd_small: seq[UsedCommand]

    try:
        sort_cmd_small = sort_cmd[0..arg.count]
    except IndexDefect:
        sort_cmd_small = sort_cmd[0..sort_cmd.len() - 1]
    

    for l in sort_cmd_small:
        highest_sort_usage_list.add(l.count)

    let highest_sort_usage_count = max(highest_sort_usage_list)

    for commands in sort_cmd_small:
        let display_command = commands.name
        let display_count = commands.count
        
        let percent_raw = $((display_count / total_cmds_count) * 100)
        var percent: string
        try:
            percent = percent_raw[0..3]
        except IndexDefect:
            percent = percent_raw[0..percent_raw.len() - 1]
        let progress = progress_bar(highest_sort_usage_count, display_count, arg)
        echo f"{progress} {display_command} {'\t'}- {display_count} ({percent}%)"
        remaining+=display_count

    if sort_cmd_small.len() != sort_cmd.len():
        let remaining_percent_raw = $(((total_cmds_count - remaining) / total_cmds_count) * 100)
        var remaining_percent: string
        try:
            remaining_percent = remaining_percent_raw[0..3]
        except IndexDefect:
            remaining_percent = remaining_percent_raw[0..remaining_percent_raw.len() - 1]
        echo f"... {total_cmds_count - remaining} (~{remaining_percent}%) others"


proc main(): void =
    let args: ArgParser = getParse()
    let total_cmds = list_of_commands(args)
    print_commands(count_used(total_cmds), total_cmds, args)
    

when isMainModule:
    main()