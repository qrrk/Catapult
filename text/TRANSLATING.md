This document explains how translations work in Catapult, how the data is structured, and how to start working on a new translation.

# Translations in Godot

Godot engine provides two options for dealing with translations: CSV files and GNU gettext (.po files). For this project I chose the former approach because of its ease of use (particularly to non-programmers).

For more details, see [Internationalizing games](https://docs.godotengine.org/en/stable/tutorials/i18n/internationalizing_games.html) and [Importing translations](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_translations.html#doc-importing-translations) in Godot documentation.

# How CSV translations work

Almost every piece of text appearing anywhere in the application (button names, settings, tooltips, log messages) needs a variant in every supported language. Translated strings are stored in CSV files (a very basic spreadsheet format). The first column of each CSV file contains a unique _key_ for each string, which is used to find and load it. Other columns contain translations of each string into different languages, one language per column. Here's how it looks in a spreadsheet program:

![image](https://user-images.githubusercontent.com/19731636/158029071-3c2b12ba-0d8b-43df-ab80-5511f2f04574.png)

A CSV file can contain multiple languages, or just one. Also, all strings used in the app can be crammed into a single CSV file or spread over multiple. The system is rather flexible.

# How translations are organized in Catapult

Until recently, almost all translated strings in Catapult were stored in a single large CSV file, which was getting increasingly hard to work with as more languages were added. Now, the arrangement is much more granular:

- Every supported language has a dedicated folder in `text/`.
- Each language folder has a number of CSV files, containing only strings in that one language.
- Each CSV file is also limited in scope and contains only strings pertaining to a certain part of the app.

This system makes translation data easier to manage and more friendly to version control.

# How to add your own translation

_Tip:_ you can use Excel, LibreOffice, or even a plain text editor like Notepad to work with the CSV files. In fact, I myself prefer editing them as plain text.

1. Fork the repository and clone it.
2. Duplicate the `text/en/` directory and name it with the two-letter code of your language. Translating from other languages is not recommended. English is the original language for this project, so it's best to use it as the base for your translation to avoid distortions.
3. Edit each CSV file inside your language folder. Replace `en` in the header row with your own language (do not forget this step!), then replace the strings in English with your translations.
4. Open the project in Godot and go to _Project → Project Settings → Localization → Translations_. Click _Add_ and navigate to your language folder. Select all of `.translation` files generated from your CSVs and click _Open_.
5. Now you can "play-test" your translation by editing the config file of Catapult, `catapult_settings.json`, and replacing the value of `launcher_locale` with your new localization. Run the launcher from Godot editor, look around and make sure everything looks good.
6. Optionally, integrate your translation into launcher settings. This usually involves adding a new item to the language drop-down and editing `SettingsUI.gd`. If you don't feel comfortable doing that, I can do this step for you later.
7. Commit your changes and create a pull request!

# Tips and things to watch out for

- Some UI elements may break the layout if their text is too long. Avoid being unnecessarily verbose, expecially in button titles. Keep in mind that element titles don't have to be exceedingly clear, since most of them also have tooltips to clear up any confusion.
- Remember to keep/add line breaks in tooltips. Godot doesn't do automatic word wrap in tooltips, so they may go off-screen if the individual lines are too long.
- Don't strive for word-for-word translations at all costs. If you think rephrasing a string will make it more clear and/or concise in your language, go for it!
