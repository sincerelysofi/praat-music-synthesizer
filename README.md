# Praat music synthesizer

This program written in Praat script reads the instructions from a score file stored in .txt format and plays music from the instructions included within. Some sample scores are included in the `scores` folder.

## Usage

Load ```music_synthesizer.praat``` in Praat and then run it. You will be prompted for a score to run. The music will be played and then saved to a wave file.

To prevent roboticness, each synthesised note has a very brief random attack length and a very brief random decay length. Additionally, each hertz is very minutely randomised.

## Score format
Scores are formatted in the following manner:

### Header
The header includes three lines:

  Tempo (bpm)
  Song length (measures)
  Number of channels
  Instrument for each channel (tab delimited)

The available instruments are:
1. Sine wave
2. Triangle wave
3. Square wave
4. Sawtooth wave

### Score
Each line contains the instructions for one channel, followed by a line for the next channel and so on. Once there is a line for each channel, the following line is treated as the next measure. Lines beginning with the pound sign ```#``` and blank lines are ignored.

Each line contains a tab-delimited series of notes in the following format:
* Tone - Tones can be A, B, C, D, E, F or G and may be followed by a # to represent a sharp.
* Octave - The octave the tone comes from, i.e. A4 = 440 Hz.
* Duration - Presents the fraction of a note, i.e. 4 = quarter note, 8 = eighth note.

Alternatively, a note may be a rest in the following format:
* ```R``` - Indicating rest
* Duration - Same format as above.
