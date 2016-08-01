SET modulespath="%homedrive%%homepath%\Documents\WindowsPowerShell\Modules\Register-WorkTime"
rd /s /q %modulespath%
md %modulespath%
copy *.ps?1 %modulespath%