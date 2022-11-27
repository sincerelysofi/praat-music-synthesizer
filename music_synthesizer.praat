# Music synthesizer and player for praat
# Sofia Lee
# 2021
# v. alpha
# 
# This script loads .txt files which have been pre-formatted
# with music data. Then it generates synths that play all the data,
# note by note. Finally, it plays the output and then saves
# it as a .wav file
#
# To do:
#	velocity
#	convolution synthesis
#	visual output and interface
#	parsing error detection
#	tonality definition
#	noise channel

@initialize
@main

procedure initialize
	clearinfo

	# Define all the tones
	tone ["C"] = 0
	tone ["C#"] = 1
	tone ["Db"] = 1
	tone ["D"] = 2
	tone ["D#"] = 3
	tone ["Eb"] = 3
	tone ["E"] = 4
	tone ["F"] = 5
	tone ["F#"] = 6
	tone ["Gb"] = 6
	tone ["G"] = 7
	tone ["G#"] = 8
	tone ["Ab"] = 8
	tone ["A"] = 9
	tone ["A#"] = 10
	tone ["Bb"] = 10
	tone ["B"] = 11
	
	# Define all the channels
	patches$# = {"sine",
			... "triangle",
			... "square",
			... "sawtooth"}
	
	current_line = 0
	current_measure = 0
endproc

procedure main
	# Ask the user to load a file
	file$ = chooseReadFile$: "Open a score"
	
	# Load the score
	music = Read Strings from raw text file: file$
	appendInfoLine: "Opening ", file$, "..."
	
	# Break the score down into measures and begin parsing
	line_num = Get number of strings
	
	appendInfoLine: "Parsing header..."
	@read_header
	
	# Central loop for interpreting instructions
	for i from 5 to line_num
		instruction$ = Get string: i
		@parse_instruction: instruction$
		selectObject: music
	endfor
	
	# Generates the final output object
	selectObject: all_measures#
	output = Concatenate
	removeObject: all_measures#, music
	
	# Save the output as WAV
	Save as WAV file: file$ - ".txt" + ".wav"
	appendInfoLine:"Output file successfully created"
	
	# Now ask the user whether to play the output object
	beginPause: "Rendering complete"
		comment: "Score has successfully rendered and saved. Click Play to begin playing."
	clicked = endPause: "Play", "Close", 1, 1
	if clicked = 1
		Play
	endif
	
	Remove
endproc

# Reads the header of a music file.
# Headers have the following format:
# 1:	bpm
# 2:	number of measures
# 3.	number of channels
# 4.	instrument for each channel
procedure read_header
	.bpm_$ = Get string: 1
	bpm = number(.bpm_$)
	appendInfoLine: "bpm set to: ", bpm
	
	.measure_$ = Get string: 2
	measures = number(.measure_$)
	all_measures# = zero#(measures)
	appendInfoLine: "song length (measures): ", measures
	
	.channels_$ = Get string: 3
	channels = number(.channels_$)
	channel_objects# = zero#(channels)
	chan_instr$# = empty$# (channels)
	appendInfoLine: "number of channels: ", channels
	
	.instruments_$ = Get string: 4
	.instr_line = Create Strings as tokens: .instruments_$, tab$
	.instr_num = Get number of strings
	
	for c to .instr_num
		.sel_patch$ = Get string: c
		chan_instr$[c] = patches$#[number(.sel_patch$)]
		appendInfoLine: "channel ", c, ": ", chan_instr$[c]
	endfor
	
	Remove
	selectObject: music
endproc

# This reads a line of the music instruction
procedure parse_instruction: .instruction$
	# We want to ignore comments and blank lines
	if left$(.instruction$) <> "#" and left$(.instruction$) <> "" 
		cur_channel = current_line mod channels + 1
		current_line += 1

		.current = Create Strings as tokens: .instruction$, tab$
		.notes_in_bar = Get number of strings
		
		sound_objects_current_bar# = zero#(.notes_in_bar)
		
		# Go through and interpret all the notes in the line
		for j to .notes_in_bar
			appendInfoLine: "parsing note ", j, " of channel ", cur_channel
			.current_note$ = Get string: j
			
			# Retrieve the note properties
			.note_properties = Create Strings as tokens: .current_note$, " "
			
			# Get the name of the current tone
			.cn_tone$ = Get string: 1
			
			# If it's not a rest, then treat it like a note
			if .cn_tone$ <> "R"
				.octave_$ = Get string: 2
				.cn_octave = number(.octave_$)

				.duration_$ = Get string: 3
				.cn_duration = number(.duration_$)
				
				# I'll put velocity back in later when I figure it out
				;.cn_velocity = Get string: 4
				.cn_velocity = randomInteger(15, 20)
				@make_tone: chan_instr$[cur_channel], .cn_tone$, .cn_octave, .cn_duration, .cn_velocity
			else
				# Generate silence if it's a rest
				.rest_duration_$ = Get string: 2
				.rest_duration = number(.rest_duration_$)
				@make_rest: .rest_duration
			endif

			removeObject: .note_properties
			
			# We have to reselect the current measure
			# so we can proceed to the next note
			selectObject: .current
		endfor

		@synthesize_measure
		
		channel_objects#[cur_channel] = selected()
		if cur_channel = channels
			@combine_channels: channel_objects#
		endif
		
		removeObject: .current
		
	endif
endproc

procedure make_rest: .duration
	.sound = Create Sound from formula: "rest", 1, 0,
		... 240 / .duration / bpm, 44100, "0"
	sound_objects_current_bar#[j] = .sound
endproc

procedure make_tone: patch$ .tone$ .octave .duration .velocity
	# Calculate the hertz from the given tone and octave
	# Each tone is also slightly detuned, which makes the
	# harmonies sound more 'natural'
	.hertz = 2^((tone[.tone$] + 3) / 12) * 2^(.octave - 5) * 440 * randomGauss(1,0.001)
	.duration += randomGauss(0, 0.0001)
	
	# Load the appropriate patch
	if patch$ = "sine"
		.formula$ = "sin(2 * pi * .hertz * x)"
	elif patch$ = "triangle"
		.formula$ = "4 * abs((x * .hertz) - floor(1/2 + (x * .hertz))) - 1"
	elif patch$ = "square"
		.formula$ = "(-1) ^ floor(2 * .hertz * x)"
	elif patch$ = "sawtooth"
		.formula$ = "2 * ((x * .hertz) - floor(1/2 + (x * .hertz)))"
	endif
	
	.sound = Create Sound from formula: "tone", 1, 0,
		... 240 / .duration / bpm, 44100,
		... "(.velocity / 100) * " + .formula$
	
	# Soften it a tiny bit with a fade
	Fade in: 0, 0, 0.01 * randomGauss(1,0.25), "no"
	
	.end_time = Get end time
	.fade_duration = 0.04 * randomGauss(1,0.25)
	Fade out: 0, .end_time - .fade_duration, .fade_duration, "no"
	
	sound_objects_current_bar#[j] = .sound
endproc

# Combines all the channels into a measure
# and then removes all the related objects
procedure synthesize_measure
	appendInfoLine: "Concatenating... "
	selectObject: sound_objects_current_bar#
	Concatenate
	removeObject: sound_objects_current_bar#
endproc

# Takes a vector of objects and combines it into a stereo sound
procedure combine_channels: .sounds#
	selectObject: .sounds#
	.output = Combine to stereo
	
	# Add the new measure to the list of all measures
	current_measure += 1
	all_measures#[current_measure] = .output

	appendInfoLine: "Completed measure ", current_measure, " of ", measures
	removeObject: .sounds#
endproc
