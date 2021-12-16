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
	var prs = _settings.read("num_prs_to_request")
	var dda_pr_url = "https://api.github.com/repos/cleverraven/cataclysm-dda/pulls?state=closed&sort=updated&direction=desc&per_page=" + prs
	var bn_pr_url = "https://api.github.com/repos/cataclysmbnteam/Cataclysm-BN/pulls?state=closed&sort=updated&direction=desc&per_page=" + prs
	var headers = ["user-agent: CatapultGodotApp"]
	var pat = _settings.read("github_pat")
	if (pat.length() == 40):
		headers.push_back("Authorization: token " + pat)
	if _dda_pr_data.length() < 65 and game_selected == "dda":
		_dda_pr_data = "Downloading recent DDA PRs. Please wait..."
		_ddaPullRequests.request(dda_pr_url, headers)
		_changelogTextBox.clear()
		_changelogTextBox.append_bbcode(_dda_pr_data)
	if _bn_pr_data.length() < 65 and game_selected == "bn":
		_bn_pr_data = "Downloading recent BN PRs. Please wait..."
		_bnPullRequests.request(bn_pr_url, headers)
		_changelogTextBox.clear()
		_changelogTextBox.append_bbcode(_bn_pr_data)
	_changelogTextBox.clear()
	if game_selected == "dda":
		_changelogTextBox.append_bbcode(_dda_pr_data)
	else:
		_changelogTextBox.append_bbcode(_bn_pr_data)

func _on_DDAPullRequests_request_completed(result, response_code, headers, body):
	if response_code != 200:
		_dda_pr_data = "Error retrieving data from the GitHub API. (Response code: " + str(response_code) + ")"
	else:
		_dda_pr_data = process_pr_data(parse_json(body.get_string_from_utf8()))
	_changelogTextBox.clear()
	_changelogTextBox.append_bbcode(_dda_pr_data)

func _on_BNPullRequests_request_completed(result, response_code, headers, body):
	if response_code != 200:
		_bn_pr_data = "Error retrieving data from the GitHub API. (Response code: " + str(response_code) + ")"
	else:
		_bn_pr_data = process_pr_data(parse_json(body.get_string_from_utf8()))
	_changelogTextBox.clear()
	_changelogTextBox.append_bbcode(_bn_pr_data)

func process_pr_data(pr_data):
	var pr_array = []
	for json in pr_data:
		if json["merged_at"] == null or json["merged_at"] == "null" :
			continue
		var pr = PullRequest.pullrequest_from_datestring(json["merged_at"], json["title"], json["html_url"])
		pr_array.push_back(pr)
	pr_array.sort_custom(PullRequest, "compare_to")
	var now = OS.get_datetime(true)
	var latest_year = now["year"] + 1
	var latest_month = now["month"]
	var latest_day = now["day"]
	var mon_str = PullRequest.format_two_digit(str(latest_month))
	var day_str = PullRequest.format_two_digit(str(latest_day))
	var r_val =""
	for pr in pr_array:
		#print(str(pr.get_year()) + "-" + str(pr.get_month()) + "-" + str(pr.get_day()))
		var switch_date = false
		switch_date = switch_date or (pr.get_year() < latest_year)
		switch_date = switch_date or (pr.get_month() < latest_month)
		switch_date = switch_date or (pr.get_day() < latest_day)
		if switch_date:
			latest_year = pr.get_year()
			latest_month = pr.get_month()
			latest_day = pr.get_day()
			mon_str = PullRequest.format_two_digit(latest_month)
			day_str = PullRequest.format_two_digit(latest_day)
			r_val = r_val + "\n--- " + str(latest_year) + "-" + mon_str+ "-" + day_str + " ---\n"
		r_val = r_val + " * [url=" + pr.get_link() + "]" + pr.get_summary() + "[/url]\n"
	return r_val

func _on_ChangelogText_meta_clicked(meta):
	OS.shell_open(str(meta))

class PullRequest:
	var timestring setget set_timestring,get_timestring
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
	
	func set_timestring(t):
		timestring = t
	
	func get_timestring():
		return timestring
	
	static func format_two_digit(time):
		if (str(time).length() == 1):
			return "0" + str(time)
		return str(time)
	
	# Sorts dates in descending order (that is, the latest date comes first).
	static func compare_to(a, b):
		return a.timestring > b.timestring
	
	# We just need to get Github API strings. Nothing else.
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
		r_val.set_timestring(date)
		return r_val
	

	
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
