# Register-WorkTime
Update your worktime on **Toggl**, aggregating data from **WakaTime**, **Visual Studio Online** and the oficial appointment system used at *Take.net*.

## Prerequisites
- cURL installed in place of the default `curl` alias used for `Invoke-WebRequest`. See [this link](http://thesociablegeek.com/azure/using-curl-in-powershell/) for details.

## How to install it
- Download and unzip this repository
- Run Install-Module.bat to install the module on powershell

## How to use it?
It is recommended to registeran  alias like `rwt` and in your PowerShell profile.

### Editing your Powershell profile
To check if you have a powershell profile, enter: `Test-Path $profile`. If it returns False, you need to create a profile.

To create a powershell profile, enter: `New-Item $profile -force -itemtype file`.

To edit your powershell profile, enter: `notepad $profile`.

Insert the following lines to ensure you will have the default `curl` alias removed and the new `inpid` alias registered every time you open the PowerShell console.

```
Import-Module Register-WorkTime
while (test-path alias:curl) { remove-item alias:curl }
while ((test-path alias:rwt) -eq $false) { new-alias rwt Register-WorkTime }
```

If you need to load your profile manually, enter: `. $profile`.
If you use [Cmder](http://www.cmder.net), see [this](https://github.com/cmderdev/cmder/issues/505).

### Updating your worktime registry on Toggl

In PowerShell, type `Register-WorkTime`, or `rwt` and inform the required parameters.

## Parameterization
In your first call, some parameters must be informed. After that, they are stored in the file `%appdata%\Register-WorkTime\user.config` and are not required anymore.

- Print usage options:
`--help` or `-h`
- Inform your wakatime api key:
`--wakatime-apikey` or `-w`
- Inform your toggl api token:
`--toggl-apitoken` or `-t`
- Inform the path for your time clock excel file:
`--clock-file` or `-c`