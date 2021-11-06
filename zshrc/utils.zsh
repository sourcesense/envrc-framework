function get_time() {
	if has gdate ; then
		gdate +%s%N
	else
		date +%s
	fi
}

function get_elapsed() {
	local start_time="$1"
	end_time=$(get_time)
	if has gdate ; then
		local nanos_in_sec=1000000000
		if has awk ; then
			local scale=10
			local secs="$(awk "BEGIN { print int($scale * (($end_time - $start_time) / $nanos_in_sec)) / $scale }")"
			echo "$secs seconds"
		else
			echo "$(( (end_time - start_time) / nanos_in_sec )) seconds"
		fi
	else
		echo "$((end_time - start_time)) seconds"
	fi
}

SCRIPT_START_TIME="$(get_time)"

export ZSH_CACHE_DIR=~/.cache/zsh
mkdir -p $ZSH_CACHE_DIR

function emit() {
	echo -n "$*"
}

function prologue() {
	local message="$*"
	emit "$message ... "
	ITEMS=0
	START_TIME="$(get_time)"
}

function item() {
	local item_text="$*"
	if (( ITEMS > 0 )) ; then
		emit ", "
	fi
	emit "$item_text"
	ITEMS=$(( ITEMS + 1 ))
}

function iteminfo() {
	local info_text="$*"
	emit " $info_text"
}

function epilogue() {
	if (( ITEMS > 0 )) ; then
		emit "."
	fi
	emit " DONE!"
	emit " [in $(get_elapsed "$START_TIME")]"
	echo
	unset START_TIME
}

function include_non_empty() {
	local script_name="$1"
	if [[ -s "$script_name" ]]; then
		source "$script_name"
		iteminfo "✔︎"
	else
		iteminfo "⚠️"
	fi
}

function complete_startup() {
    echo "Shell was set up in $(get_elapsed "$SCRIPT_START_TIME") 🏁."
    echo

    unset SCRIPT_START_TIME
}
