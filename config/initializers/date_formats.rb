# 日付フォーマットの設定
Date::DATE_FORMATS[:default] = "%Y年%m月%d日"
Date::DATE_FORMATS[:short] = '%m/%d'
Date::DATE_FORMATS[:long] = '%Y年%m月%d日'
Date::DATE_FORMATS[:year_month] = '%Y年%m月'

Time::DATE_FORMATS[:default] = "%Y年%m月%d日 %H:%M"
Time::DATE_FORMATS[:short] = '%m/%d %H:%M'
Time::DATE_FORMATS[:long] = '%Y年%m月%d日 %H:%M:%S'
Time::DATE_FORMATS[:time] = '%H:%M'
Time::DATE_FORMATS[:year_month] = '%Y年%m月'
Time::DATE_FORMATS[:date_only] = '%Y年%m月%d日' 