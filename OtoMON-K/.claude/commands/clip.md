---
allowed-tools: Bash(powershell:*), Read
description: Grab an image from clipboard for analysis
---

Capture the clipboard image by running this PowerShell command:

powershell -Command "Add-Type -AssemblyName System.Windows.Forms; $img = [System.Windows.Forms.Clipboard]::GetImage(); if ($img) { $path = \"$env:TEMP\clipboard_$(Get-Date -Format 'yyyyMMdd_HHmmss').png\"; $img.Save($path); Write-Host $path } else { Write-Error 'No image in clipboard'; exit 1 }"

Then read the image file at the output path to analyze it. After analyzing, address the user's request: $ARGUMENTS