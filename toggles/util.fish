. (dirname (status filename))/../util.fish

function move-client -a selector workspace
    if hyprctl -j clients | jq -e 'first(.[] | select('$selector')).workspace.name != "special:'$workspace'"' > /dev/null
        # Window not in correct workspace
        set -l window_addr (hyprctl -j clients | jq -r 'first(.[] | select('$selector')).address')
        hyprctl dispatch movetoworkspacesilent "special:$workspace,address:$window_addr"
    end
end

function spawn-client -a selector spawn
    # Spawn if doesn't exist
    hyprctl -j clients | jq -e "first(.[] | select($selector))" > /dev/null
    set -l stat $status
    if test $stat != 0
        eval "$spawn & disown"
    end
    test $stat != 0  # Exit 1 if already exists
end

function jq-var -a op json
    jq -rn --argjson json "$json" "\$json | $op"
end

function toggle-workspace -a workspace
    set -l apps (get-config "toggles.$workspace.apps")

    for i in (seq 0 (math (jq-var 'length' "$apps") - 1))
        set -l app (jq-var ".[$i]" "$apps")
        set -l action (jq-var '.action' "$app")
        set -l selector (jq-var '.selector' "$app")
        set -l extra_cond (jq-var '.extraCond' "$app")

        test $extra_cond = null && set -l extra_cond true
        if eval $extra_cond
            string match -qe -- 'spawn' $action && spawn-client $selector (jq-var '.spawn' "$app")
            string match -qe -- 'move' $action && move-client $selector $workspace
        end
    end

    hyprctl dispatch togglespecialworkspace $workspace
end
