extends Node
# This node stores tips of the day and picks one at random when asked.


const _TOTD = [
	# These used to be hardcoded, but now it is just a list of translation keys.
	
	"tip_os_hopping",
	"tip_dual_install",
	"tip_downgrading",
	"tip_stock_mods",
	"tip_mod_multi_install",
	"tip_modpack_update",
	"tip_debug_mode",
	"tip_bug_reporting",
	"tip_backup_caveat",
	"tip_multi_install",
]


func get_tip() -> String:
	
	var index = OS.get_system_time_msecs() % len(_TOTD)
	return tr(_TOTD[index])
