extends Node

onready var _settings = $"/root/SettingsManager"
onready var _ddaPullRequests = $DDAPullRequests
onready var _bnPullRequests = $BNPullRequests
onready var _changelogTextBox = $"../ChangelogText"

var _dda_pr_data = "Downloading recent DDA PRs. Please wait..."
var _bn_pr_data = "Downloading recent BN PRs. Please wait..."

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func download_pull_requests():
	var game_selected = _settings.read("game")
	var dda_pr_url = "https://api.github.com/repos/cleverraven/cataclysm-dda/pulls?state=closed&sort=updated&direction=desc&per_page=100"
	var bn_pr_url = "https://api.github.com/repos/cataclysmbnteam/Cataclysm-BN/pulls?state=closed&sort=updated&direction=desc&per_page=100"
	if _dda_pr_data.length() < 45 and game_selected == "dda":
		_ddaPullRequests.request(dda_pr_url,["Authorization: token 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", "user-agent: GodotApp"])
	if _bn_pr_data.length() < 45 and game_selected == "bn":
		_bnPullRequests.request(bn_pr_url,["Authorization: token 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", "user-agent: GodotApp"])
	if game_selected == "dda":
		_changelogTextBox.set_text(_dda_pr_data)
	else:
		_changelogTextBox.set_text(_bn_pr_data)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_DDAPullRequests_request_completed(result, response_code, headers, body):
	if response_code != 200:
		_dda_pr_data = "Error retrieving data from the GitHub API."
	else:
		_dda_pr_data = process_pr_data(parse_json(body.get_string_from_utf8()))
	_changelogTextBox.set_text(_dda_pr_data)


func _on_BNPullRequests_request_completed(result, response_code, headers, body):
	if response_code != 200:
		_bn_pr_data = "Error retrieving data from the GitHub API."
	else:
		_bn_pr_data = process_pr_data(parse_json(body.get_string_from_utf8()))
	_changelogTextBox.set_text(_bn_pr_data)
	
func process_pr_data(pr_data):
	var pr_array = []
	for json in pr_data:
		if json["merged_at"] == null or json["merged_at"] == "null" :
			continue
		var pr = PullRequest.pullrequest_from_datestring(json["merged_at"], json["title"], json["html_url"])
		pr_array.push_back(pr)
	pr_array.sort_custom(PullRequest, "compare_to")
	var now = OS.get_datetime(true)
	var latest_year = now["year"]
	var latest_month = now["month"]
	var latest_day = now["day"]
	var r_val = str(latest_year) + "-" + str(latest_month) + "-" + str(latest_day) + ":\n"
	for pr in pr_array:
		var switch_date = false
		switch_date = switch_date or (pr.get_year() < latest_year)
		switch_date = switch_date or (pr.get_month() < latest_month)
		switch_date = switch_date or (pr.get_day() < latest_day)
		if switch_date:
			latest_year = pr.get_year()
			latest_month = pr.get_month()
			latest_day = pr.get_day()
			r_val = r_val + "\n" + str(latest_year) + "-" + str(latest_month) + "-" + str(latest_day) + ":\n"
		r_val = r_val + pr.get_summary() + "\n"
	return r_val

class PullRequest:
	var year setget ,get_year
	var month setget ,get_month
	var day setget ,get_day
	var hour setget ,get_hour
	var minute setget ,get_minute
	var second setget ,get_second
	var summary setget ,get_summary
	var link setget ,get_link
	
	func get_year():
		return year
	
	func get_month():
		return month
	
	func get_day():
		return day
	
	func get_hour():
		return hour
		
	func get_minute():
		return minute
	
	func get_second():
		return second
		
	func get_summary():
		return summary
		
	func get_link():
		return link
	
	#We just need to get Github API strings. Nothing else.
	static func pullrequest_from_datestring(date, sum, link):
		var r_val = PullRequest.new(
			int(date.substr(0,4)),
			int(date.substr(5,2)),
			int(date.substr(8,2)),
			int(date.substr(11,2)),
			int(date.substr(14,2)),
			int(date.substr(16,2)),
			sum,
			link)
		return r_val
	
	# Sorts dates in descending order (that is, the latest date comes first).
	static func compare_to(a, b):
		if a.year < b.year:
			return false
		if a.month < b.month:
			return false
		if a.day < b.day:
			return false
		if a.hour < b.hour:
			return false
		if a.minute < b.minute:
			return false
		if a.second < b.second:
			return false
		return true
	
	func _init(y, mo, d, h, mi, s, sum, url):
		year = y
		month = mo
		day = d
		hour = h
		minute = mi
		second = s
		summary = sum
		link = url
	
	func print_date():
		return str(year) + "-" + str(month) + "-" + str(day)
