extends Node

onready var _settings = $"/root/SettingsManager"
onready var _ddaPullRequest = $DDAPullRequests
onready var _bnPullRequest = $BNPullRequests
onready var _changelogTextBox = $"../ChangelogText"

var _ddaPRUrl = "https://api.github.com/repos/cleverraven/cataclysm-dda/pulls?state=closed&sort=updated&direction=desc&per_page=100&page="
var _bnPRUrl = "https://api.github.com/repos/cataclysmbnteam/Cataclysm-BN/pulls?state=closed&sort=updated&direction=desc&per_page=100&page="

var _ddaPRData = null
var _bnPRData = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func download_pull_requests():
	if _ddaPRData == null:
		_ddaPullRequest.request(_ddaPRUrl + str(1),["user-agent: GodotApp"])
	#if _bnPRData == null:
		#_bnPullRequest.request(_bnPRUrl + str(1),["user-agent: GodotApp"])

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_DDAPullRequests_request_completed(result, response_code, headers, body):
	_ddaPRData = process_pr_data(parse_json(body.get_string_from_utf8()))


func _on_BNPullRequests_request_completed(result, response_code, headers, body):
	_bnPRData = process_pr_data(parse_json(body.get_string_from_utf8()))
	
func process_pr_data(prData):
	var currentDate = OS.get_datetime(true)
	var rVal = ""
	for json in prData:
		pass
