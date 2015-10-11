
; #FUNCTION# ====================================================================================================================
; Name ..........: Collect
; Description ...:
; Syntax ........: Collect()
; Parameters ....:
; Return values .: None
; Author ........: Code Gorilla #3
; Modified ......: Sardo 2015-08, KnowJack(Aug 2015), kaganus (August 2015), MonkeyHunter (2015-8)
; Remarks .......: This file is part of MyBot, previously known as ClashGameBot. Copyright 2015
;                  MyBot is distributed under the terms of the GNU GPL
; Related .......:
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================
Func Collect()
	If $RunState = False Then Return

	ClickP($aAway, 1, 0, "#0332") ;Click Away

	If $iChkCollect = 0 Then Return

	Local $collx, $colly, $i = 0

	VillageReport(True, True)
	$tempCounter = 0
	While ($iGoldCurrent = "" Or $iElixirCurrent = "" Or ($iDarkCurrent = "" And $iDarkStart <> "")) And $tempCounter < 3
		$tempCounter += 1
		VillageReport(True, True)
	WEnd
	Local $tempGold = $iGoldCurrent
	Local $tempElixir = $iElixirCurrent
	Local $tempDElixir = $iDarkCurrent

	SetLog("Collecting Resources", $COLOR_BLUE)
	If _Sleep($iDelayCollect2) Then Return

	If $listResourceLocation <> "" Then
		Local $ResourceLocations = StringSplit($listResourceLocation, "|", $STR_NOCOUNT)
		If $debugSetlog = 1 Then Setlog("Before shuffle: " & $listResourceLocation, $COLOR_PURPLE)
		_ArrayShuffle($ResourceLocations) ; Random shuffle resource locations to avoid bot detection
		If @error Then Setlog("$ResourceLocations Array Shuffle fail - " & @error, $COLOR_RED)
		Local $stext = ""
		For $j = 0 To UBound($ResourceLocations) - 1 ; reassemble array into string for display
			$stext &= $ResourceLocations[$j] & "|"
		Next
		If $debugSetlog = 1 Then Setlog("After shuffle: " & $stext, $COLOR_PURPLE)
		For $i = 1 To UBound($ResourceLocations) - 1
			If $ResourceLocations[$i] <> "" Then
				$pixel = StringSplit($ResourceLocations[$i], ";")
				If isInsideDiamondXY($pixel[1], $pixel[2]) Then
					click($pixel[1], $pixel[2], 1, 0, "#0331")
				Else
					SetLog("Error in Mines/Collector locations found, finding positions again", $COLOR_RED)
					IniDelete($building, "other", "listResource")
					If _Sleep($iDelayCollect2) Then Return
					$listResourceLocation = ""
					BotDetectFirstTime()
					IniWrite($building, "other", "listResource", $listResourceLocation)
					ExitLoop
				EndIf
				If _Sleep($iDelayCollect2) Then Return
			EndIf
		Next
	EndIf

	checkAttackDisable($iTaBChkIdle) ; Early Take-A-Break detection

	; Split the collector search area into 8 zones that overlap the middle by size of image
	Static Local $aZones[8][4] = [ _
			[45, 160, 243, 322], [243, 25, 434, 322], [426, 25, 627, 322], [619, 165, 812, 322], _
			[45, 298, 243, 460], [243, 298, 430, 600], [426, 298, 627, 600], [619, 298, 812, 465]]

	_ArrayShuffle($aZones) ; randomize the order of the collection zones
	If @error Then Setlog("Array Shuffle fail - " & @error, $COLOR_RED)

	$findImage = "*" & "20" & " " & @ScriptDir & "\images\collect.png"
	For $i = 0 To UBound($aZones) - 1
		If $debugSetlog = 1 Then Setlog("Zone #:" & $i & ", " & $aZones[$i][0] & "|" & $aZones[$i][1] & ", " & $aZones[$i][2] & "|" & $aZones[$i][3], $COLOR_PURPLE)
		If _Sleep($iDelayCollect1) Or $RunState = False Then ExitLoop
		Local $iloopexit = 0
		For $j = 0 To 12
			_CaptureRegion($aZones[$i][0], $aZones[$i][1], $aZones[$i][2], $aZones[$i][3])
			If $debugSetlog = 1 Then Setlog("Collector search #:" & $j, $COLOR_PURPLE) ; Debug
			$result = DllCall($LibDir & "\CGBPlugin.dll", "str", "ImageSearchEx", "int", 0, "int", 0, "int", $aZones[$i][2] - $aZones[$i][0], "int", $aZones[$i][3] - $aZones[$i][1], "str", $findImage, "ptr", $hHBitmap)
			If IsArray($result) Then ; If dll error then exit for-next loops
				If $result[0] = "0" Then
					$iloopexit += 1 ; increase loop exit counter
					Switch $iloopexit
						Case 0 To 1
							ContinueLoop ; try twice with existing region capture
						Case 2
							_CaptureRegion($aZones[$i][0], $aZones[$i][1], $aZones[$i][2], $aZones[$i][3]) ; capture region again to fix image issues
						Case 3 To 100
							ExitLoop ; try 3 times then skip the zone
					EndSwitch
				EndIf
				If $debugSetlog = 1 Then Setlog("ImgSearchResult= " & $result[0], $COLOR_PURPLE)
			Else
				SetLog("Error: Image Search not working...", $COLOR_RED)
				ExitLoop 2
			EndIf
			; If $result is valid, then get the x,y location of the match and adjust location
			$array = StringSplit($result[0], "|")
			If (UBound($array) >= 4) Then
				$x = Int(Number($array[2]))
				$y = Int(Number($array[3]))
				$collx = $x + Int(Number($array[4]) / 2) ; adjust for size of image
				$colly = $y + Int(Number($array[5]) / 2)
				$collx = $x + $aZones[$i][0] ; adjust for location of the capture region
				$colly = $y + $aZones[$i][1]
				Click($collx, $colly, 1, 0, "#0330") ;Click collector
				If _Sleep($iDelayCollect1) Then ExitLoop 2 ; short delay before click away
				ClickP($aAway, 1, 0, "#0329") ;Click Away
				If _Sleep($iDelayCollect1) Then ExitLoop 2 ; delay for animation to clear before new region capture after collecting resouce
				_CaptureRegion($aZones[$i][0], $aZones[$i][1], $aZones[$i][2], $aZones[$i][3]) ; grab new region capture after each click
			EndIf
		Next
	Next

	#comments-start
		; Old collect resources code for reference only
		While 1
		If _Sleep($iDelayCollect1) Or $RunState = False Then ExitLoop
		_CaptureRegion(0, 0, 780)
		If _ImageSearch(@ScriptDir & "\images\collect.png", 1, $collx, $colly, 20) Then
		Click($collx, $colly, 1, 0, "#0330") ;Click collector
		If _Sleep($iDelayCollect1) Then Return
		ClickP($aAway, 1, 0, "#0329") ;Click Away
		ElseIf $i >= 20 Then
		ExitLoop
		EndIf
		$i += 1
		WEnd
	#comments-end

	If _Sleep($iDelayCollect3) Then Return
	checkMainScreen(False) ; check if errors during function

	VillageReport(True, True)
	$tempCounter = 0
	While ($iGoldCurrent = "" Or $iElixirCurrent = "" Or ($iDarkCurrent = "" And $iDarkStart <> "")) And $tempCounter < 3
		$tempCounter += 1
		VillageReport(True, True)
	WEnd

	If $tempGold <> "" And $iGoldCurrent <> "" Then
		$tempGoldCollected = $iGoldCurrent - $tempGold
		$iGoldFromMines += $tempGoldCollected
		$iGoldTotal += $tempGoldCollected
	EndIf

	If $tempElixir <> "" And $iElixirCurrent <> "" Then
		$tempElixirCollected = $iElixirCurrent - $tempElixir
		$iElixirFromCollectors += $tempElixirCollected
		$iElixirTotal += $tempElixirCollected
	EndIf

	If $tempDElixir <> "" And $iDarkCurrent <> "" Then
		$tempDElixirCollected = $iDarkCurrent - $tempDElixir
		$iDElixirFromDrills += $tempDElixirCollected
		$iDarkTotal += $tempDElixirCollected
	EndIf

	UpdateStats()
EndFunc   ;==>Collect
