extends WindowDialog


const _PR_URL = {
	"dda": "https://api.github.com/repos/cleverraven/cataclysm-dda/pulls",
	"bn": "https://api.github.com/repos/cataclysmbnteam/Cataclysm-BN/pulls",
}


onready var _settings = $"/root/SettingsManager"
onready var _pullRequests = $PullRequests
onready var _changelogTextBox = $Panel/Margin/VBox/ChangelogText

var _pr_data = ""


func open() -> void:
	
	download_pull_requests()
	rect_min_size = get_tree().root.size * Vector2(0.9, 0.9)
	set_as_minsize()
	popup_centered()


func download_pull_requests():
	var game_selected = _settings.read("game")
	var prs = _settings.read("num_prs_to_request")
	var url = _PR_URL[_settings.read("game")]
	url += "?state=closed&sort=updated&direction=desc&per_page=" + prs
	var headers = ["user-agent: CatapultGodotApp"]
	var pat = _settings.read("github_pat")
	if (pat.length() == 40):
		headers.push_back("Authorization: token " + pat)
	_pr_data = "Fetching recent changes from GitHub. Please wait..."
	_pullRequests.request(url, headers)
	_changelogTextBox.clear()
	_changelogTextBox.append_bbcode(_pr_data)
	_changelogTextBox.clear()
	_changelogTextBox.append_bbcode(_pr_data)


func _on_PullRequests_request_completed(result, response_code, headers, body):
	var json = parse_json(body.get_string_from_utf8())
	if response_code != 200:
		_pr_data = "Error retrieving data from GitHub API."
		_pr_data += "\n\nHTTP response code: " + str(response_code)
		if (json) and ("message" in json):
			_pr_data += "\nGitHub says: [i]%s[/i]" % json["message"]
		_pr_data += "\n\nSometimes, requests will fail repeatedly due to excessive load on the server, especially for DDA. This may depend on the time of day, your location, etc. There's little anyone can do about this. If you are registered on GitHub, you can add your PAT (Personal Access Token) to Catapult config file to increase the priority of your requests or bypass rate limits."
	else:
		_pr_data = process_pr_data(json)
	_changelogTextBox.clear()
	_changelogTextBox.append_bbcode(_pr_data)


func process_pr_data(data):
	var pr_array = []
	for json in data:
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
	
	var game_title = ""
	match _settings.read("game"):
		"dda":
			game_title = "Cataclysm: Dark Days Ahead"
		"bn":
			game_title = "Cataclysm: Bright Nights"
		_:
			game_title = "{BUG!!}"
	
	var r_val = ("Showing the last [b]%s[/b] completed pull requests (code additions) to [b]%s[/b].\n\nThe chronology may be slightly off due to GitHub API limitations.\n\nYou can click on any item to view the corresponding PR on GitHub and learn more about the change.\n"
		% [_settings.read("num_prs_to_request"), game_title])
	
	for pr in pr_array:
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
			r_val = r_val + "\n[b]" + str(latest_year) + "-" + mon_str+ "-" + day_str + "[/b]\n"
		r_val = r_val + "[indent]• [url=" + pr.get_link() + "]" + pr.get_summary() + "[/url][/indent]\n"
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


func _on_BtnCloseChangelog_pressed() -> void:
	hide()
