' MIDI Sequencer for PicoMite/PicoCalc
' A 16-step pattern-based MIDI sequencer
' Uses COM2 serial for MIDI output + internal audio

Option Explicit
Option Default None
Option Base 0


' Configuration
Const PATTERNS = 8        ' Number of patterns
Const STEPS = 16         ' Steps per pattern
Const TRACKS = 4         ' Number of tracks

' Global Variables
Dim Integer currentPattern = 0
Dim Integer currentStep = 0
Dim Integer tempo = 120  ' BPM
Dim Integer isPlaying = 0
Dim Integer isRecording = 0
Dim Integer playMode = 0 ' 0=pattern, 1=song
Dim Integer playAudio = 1 ' Enable internal audio playback

' Pattern data: pattern, step, track, note, velocity, length
Dim Integer patternData(PATTERNS-1, STEPS-1, TRACKS-1, 3)
Dim Integer songSequence(32) ' Song mode sequence
Dim Integer songLength = 4

' Timing
Dim Float stepTime
Dim Float lastStepTime

' Initialize
Init_Sequencer()

' Main Loop
Do
  CheckInput()
  If isPlaying Then
    UpdateSequencer()
  EndIf
  UpdateDisplay()
  Pause 10
Loop

End

'------------------------------------------------------------------------------
' Initialize Sequencer
'------------------------------------------------------------------------------
Sub Init_Sequencer()
  Local Integer p, s, t
  
  ' Setup MIDI output using COM2
  ' Use GP4 (TX) and GP5 (RX) for COM2
  SetPin GP4, GP5, COM2
  
  ' Now open COM2 for MIDI at 31250 baud
  Open "COM2:31250" As #1
  
  ' Audio is already configured via Option Audio at top of program
  
  ' Clear all pattern data
  For p = 0 To PATTERNS-1
    For s = 0 To STEPS-1
      For t = 0 To TRACKS-1
        patternData(p, s, t, 0) = 0   ' Note (0 = no note)
        patternData(p, s, t, 1) = 100 ' Velocity
        patternData(p, s, t, 2) = 1   ' Length in steps
        patternData(p, s, t, 3) = 0   ' Gate (on/off)
      Next t
    Next s
  Next p
  
  ' Setup default song sequence
  For p = 0 To 31
    songSequence(p) = p Mod PATTERNS
  Next p
  
  ' Calculate step time
  stepTime = 60000.0 / tempo / 4.0 ' 16th notes
  lastStepTime = Timer
  
  ' Setup display (works on all PicoMite variants)
  Cls
  
  Print "PICOMITE MIDI SEQUENCER"
  Print "======================="
  Print "MIDI out on GP4 (COM2 TX)"
  Print "Audio out on GP26/GP27"
  Print
  
  ' Create demo pattern for testing
  CreateDemoPattern()
End Sub

'------------------------------------------------------------------------------
' Update Sequencer - handle playback timing
'------------------------------------------------------------------------------
Sub UpdateSequencer()
  Local Integer currentTime
  Local Integer p
  
  currentTime = Timer
  
  If currentTime - lastStepTime >= stepTime Then
    ' Play current step
    PlayStep(currentPattern, currentStep)
    
    ' Advance to next step
    Inc currentStep
    If currentStep >= STEPS Then
      currentStep = 0
      If playMode = 1 Then ' Song mode
        Inc currentPattern
        If currentPattern >= songLength Then
          currentPattern = 0
        EndIf
        currentPattern = songSequence(currentPattern)
      EndIf
    EndIf
    
    lastStepTime = currentTime
  EndIf
End Sub

'------------------------------------------------------------------------------
' Play a single step
'------------------------------------------------------------------------------
Sub PlayStep(p As Integer, s As Integer)
  Local Integer t, note, vel, channel
  
  For t = 0 To TRACKS-1
    note = patternData(p, s, t, 0)
    vel = patternData(p, s, t, 1)
    
    If note > 0 And note < 128 Then
      channel = t + 1
      
      ' Send MIDI out
      SendMidiNoteOn(channel, note, vel)
      
      ' Play audio locally
      If playAudio Then
        PlayAudioNote(note, vel, t)
      EndIf
    EndIf
  Next t
End Sub

'------------------------------------------------------------------------------
' Play audio note using internal sound generator
'------------------------------------------------------------------------------
Sub PlayAudioNote(note As Integer, velocity As Integer, track As Integer)
  Local Float freq
  Local Integer duration
  
  ' Convert MIDI note to frequency
  ' A4 (MIDI note 69) = 440 Hz
  freq = 440.0 * 2 ^ ((note - 69) / 12.0)
  
  ' Duration in ms (short for drum hits)
  duration = 200
  
  ' Play the note using PLAY TONE (better for short notes)
  ' For stereo: use same frequency on both channels or 0 for silent channel
  If track < 2 Then
    ' Left channel
    Play Tone freq, 0, duration
  Else
    ' Right channel  
    Play Tone 0, freq, duration
  EndIf
End Sub

'------------------------------------------------------------------------------
' Send MIDI Note On
'------------------------------------------------------------------------------
Sub SendMidiNoteOn(channel As Integer, note As Integer, velocity As Integer)
  Local Integer status
  status = &H90 Or (channel - 1) ' Note On + channel (0-15)
  Print #1, Chr$(status); Chr$(note); Chr$(velocity);
End Sub

'------------------------------------------------------------------------------
' Send MIDI Note Off
'------------------------------------------------------------------------------
Sub SendMidiNoteOff(channel As Integer, note As Integer)
  Local Integer status
  status = &H80 Or (channel - 1) ' Note Off + channel
  Print #1, Chr$(status); Chr$(note); Chr$(0);
End Sub

'------------------------------------------------------------------------------
' Send MIDI All Notes Off (panic button)
'------------------------------------------------------------------------------
Sub SendAllNotesOff()
  Local Integer ch
  For ch = 1 To 16
    Print #1, Chr$(&HB0 Or (ch-1)); Chr$(123); Chr$(0);
  Next ch
  
  ' Stop audio
  Play Stop
End Sub

'------------------------------------------------------------------------------
' Check keyboard input
'------------------------------------------------------------------------------
Sub CheckInput()
  Local String k$
  
  k$ = Inkey$
  If k$ = "" Then Exit Sub
  
  Select Case k$
    Case " "
      ' Play/Stop
      isPlaying = Not isPlaying
      If isPlaying Then
        currentStep = 0
        lastStepTime = Timer
        Print "PLAYING"
      Else
        SendAllNotesOff()
        Print "STOPPED"
      EndIf
      
    Case "a", "A"
      ' Toggle audio playback
      playAudio = Not playAudio
      If playAudio Then
        Print "Audio: ON"
      Else
        Print "Audio: OFF"
      EndIf
      
    Case "r", "R"
      ' Record toggle
      isRecording = Not isRecording
      If isRecording Then
        Print "Record: ON"
      Else
        Print "Record: OFF"
      EndIf
      
    Case "+", "="
      ' Increase tempo
      Inc tempo, 5
      If tempo > 300 Then tempo = 300
      stepTime = 60000.0 / tempo / 4.0
      Print "Tempo: "; tempo; " BPM"
      
    Case "-", "_"
      ' Decrease tempo
      Inc tempo, -5
      If tempo < 40 Then tempo = 40
      stepTime = 60000.0 / tempo / 4.0
      Print "Tempo: "; tempo; " BPM"
      
    Case "p", "P"
      ' Next pattern
      Inc currentPattern
      If currentPattern >= PATTERNS Then currentPattern = 0
      Print "Pattern: "; currentPattern + 1
      
    Case "c", "C"
      ' Clear current pattern
      ClearPattern(currentPattern)
      Print "Pattern "; currentPattern + 1; " cleared"
      
    Case "s", "S"
      ' Save pattern
      SavePattern(currentPattern)
      
    Case "l", "L"
      ' Load pattern  
      LoadPattern(currentPattern)
      
    Case "1" To "8"
      ' Select pattern directly
      currentPattern = Val(k$) - 1
      Print "Pattern: "; currentPattern + 1
      
    Case "d", "D"
      ' Create demo pattern
      CreateDemoPattern()
      
    Case "t", "T"
      ' Test MIDI output
      TestMidi()
      
    Case "i", "I"
      ' Show info
      ShowInfo()
      
    Case "q", "Q"
      ' Quit
      SendAllNotesOff()
      Close #1
      Print "Goodbye!"
      End
      
    Case "?"
      ' Help
      ShowHelp()
  End Select
End Sub

'------------------------------------------------------------------------------
' Update Display (text-based for compatibility)
'------------------------------------------------------------------------------
Sub UpdateDisplay()
  Static Integer lastUpdate = 0
  Static Integer lastStep = -1
  
  ' Update display every 250ms or when step changes
  If Timer - lastUpdate < 250 And lastStep = currentStep Then Exit Sub
  lastUpdate = Timer
  
  If isPlaying And lastStep <> currentStep Then
    Print "["; String$(currentStep, "*"); String$(STEPS - currentStep - 1, "-"); "] ";
    Print "P"; currentPattern + 1; " ";
    Print "S"; currentStep + 1; " ";
    Print tempo; "BPM"
    lastStep = currentStep
  EndIf
End Sub

'------------------------------------------------------------------------------
' Show sequencer info
'------------------------------------------------------------------------------
Sub ShowInfo()
  Print
  Print "=== SEQUENCER INFO ==="
  Print "Pattern: "; currentPattern + 1; " of "; PATTERNS
  Print "Step: "; currentStep + 1; " of "; STEPS
  Print "Tempo: "; tempo; " BPM"
  If isPlaying Then
    Print "Status: PLAYING"
  Else
    Print "Status: STOPPED"
  EndIf
  If isRecording Then
    Print "Record: ON"
  Else
    Print "Record: OFF"
  EndIf
  If playAudio Then
    Print "Audio: ON"
  Else
    Print "Audio: OFF"
  EndIf
  Print "Notes in pattern: "; CountNotes(currentPattern)
  Print
End Sub

'------------------------------------------------------------------------------
' Count notes in a pattern
'------------------------------------------------------------------------------
Function CountNotes(p As Integer) As Integer
  Local Integer s, t, count
  count = 0
  
  For s = 0 To STEPS-1
    For t = 0 To TRACKS-1
      If patternData(p, s, t, 0) > 0 Then Inc count
    Next t
  Next s
  
  CountNotes = count
End Function

'------------------------------------------------------------------------------
' Show help
'------------------------------------------------------------------------------
Sub ShowHelp()
  Print
  Print "=== MIDI SEQUENCER HELP ==="
  Print "SPACE - Play/Stop"
  Print "+/-   - Tempo up/down"
  Print "1-8   - Select pattern"
  Print "P     - Next pattern"
  Print "C     - Clear pattern"
  Print "D     - Load demo pattern"
  Print "S     - Save pattern"
  Print "L     - Load pattern"
  Print "T     - Test MIDI & audio"
  Print "A     - Toggle audio"
  Print "I     - Show info"
  Print "R     - Toggle record"
  Print "?     - This help"
  Print "Q     - Quit"
  Print
End Sub

'------------------------------------------------------------------------------
' Test MIDI output
'------------------------------------------------------------------------------
Sub TestMidi()
  Local Integer i
  
  Print "Testing MIDI & audio output..."
  
  ' Test left speaker
  Print "Left speaker..."
  For i = 60 To 67
    SendMidiNoteOn(1, i, 100)
    If playAudio Then
      Play Tone 440.0 * 2 ^ ((i - 69) / 12.0), 0, 150
    EndIf
    Pause 200
    SendMidiNoteOff(1, i)
  Next i
  
  Pause 300
  
  ' Test right speaker
  Print "Right speaker..."
  For i = 67 To 72
    SendMidiNoteOn(1, i, 100)
    If playAudio Then
      Play Tone 0, 440.0 * 2 ^ ((i - 69) / 12.0), 150
    EndIf
    Pause 200
    SendMidiNoteOff(1, i)
  Next i
  
  Print "Test complete!"
End Sub

'------------------------------------------------------------------------------
' Check if pattern step has any notes
'------------------------------------------------------------------------------
Function PatternHasNote(p As Integer, s As Integer) As Integer
  Local Integer t
  
  For t = 0 To TRACKS-1
    If patternData(p, s, t, 0) > 0 Then
      PatternHasNote = 1
      Exit Function
    EndIf
  Next t
  
  PatternHasNote = 0
End Function

'------------------------------------------------------------------------------
' Clear pattern
'------------------------------------------------------------------------------
Sub ClearPattern(p As Integer)
  Local Integer s, t
  
  For s = 0 To STEPS-1
    For t = 0 To TRACKS-1
      patternData(p, s, t, 0) = 0
      patternData(p, s, t, 1) = 100
      patternData(p, s, t, 2) = 1
      patternData(p, s, t, 3) = 0
    Next t
  Next s
End Sub

'------------------------------------------------------------------------------
' Save pattern to SD card
'------------------------------------------------------------------------------
Sub SavePattern(p As Integer)
  Local String filename$
  Local Integer s, t, i
  
  filename$ = "pattern" + Str$(p) + ".seq"
  
  Open filename$ For Output As #2
  
  ' Write pattern data
  For s = 0 To STEPS-1
    For t = 0 To TRACKS-1
      For i = 0 To 3
        Print #2, Str$(patternData(p, s, t, i))
      Next i
    Next t
  Next s
  
  Close #2
  
  Print "Saved: "; filename$
End Sub

'------------------------------------------------------------------------------
' Load pattern from SD card
'------------------------------------------------------------------------------
Sub LoadPattern(p As Integer)
  Local String filename$
  Local Integer s, t, i, value
  
  filename$ = "pattern" + Str$(p) + ".seq"
  
  If Not Mm.Info(Exists File filename$) Then
    Print "File not found: "; filename$
    Exit Sub
  EndIf
  
  Open filename$ For Input As #2
  
  ' Read pattern data
  For s = 0 To STEPS-1
    For t = 0 To TRACKS-1
      For i = 0 To 3
        Input #2, value
        patternData(p, s, t, i) = value
      Next i
    Next t
  Next s
  
  Close #2
  
  Print "Loaded: "; filename$
End Sub

'------------------------------------------------------------------------------
' Add demo pattern for testing
'------------------------------------------------------------------------------
Sub CreateDemoPattern()
  Local Integer i
  
  ' Clear pattern 0 first
  ClearPattern(0)
  
  ' Simple drum pattern on pattern 0
  ' Track 0 = Kick (C2 = 36) - LEFT
  patternData(0, 0, 0, 0) = 36
  patternData(0, 0, 0, 1) = 127
  patternData(0, 4, 0, 0) = 36
  patternData(0, 4, 0, 1) = 100
  patternData(0, 8, 0, 0) = 36
  patternData(0, 8, 0, 1) = 127
  patternData(0, 12, 0, 0) = 36
  patternData(0, 12, 0, 1) = 100
  
  ' Track 1 = Snare (D2 = 38) - LEFT
  patternData(0, 4, 1, 0) = 38
  patternData(0, 4, 1, 1) = 120
  patternData(0, 12, 1, 0) = 38
  patternData(0, 12, 1, 1) = 120
  
  ' Track 2 = Hi-hat (F#2 = 42) - RIGHT
  For i = 0 To 15
    patternData(0, i, 2, 0) = 42
    If i Mod 2 = 0 Then
      patternData(0, i, 2, 1) = 100
    Else
      patternData(0, i, 2, 1) = 60
    EndIf
  Next i
  
  Print "Demo pattern created!"
End Sub
