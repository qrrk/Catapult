class_name TOTD
extends RefCounted
## Stores tips of the day (as translation keys) and picks one at random.


const _TOTD: Array[String] = [
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


## Returns a randomly selected, translated tip of the day.
static func get_tip() -> String:
	
	var index := Time.get_ticks_usec() % _TOTD.size()
	return TranslationServer.translate(_TOTD[index])
