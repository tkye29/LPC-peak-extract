# Save formant values for segments in the sound files of a specified directory
# Sound files must be .aif or .wav
# TextGrid files must be .textgrid
#
# This script is distributed under the GNU General Public License.
# Gina Cook April 24 2006
# MODIFIED BY TED K. KYE September 24, 2018

# directory format should be like:  targets\wav\

# Display config form 
form Save spectral peaks for all labels
comment Give the path of the directory containing the sound and TextGrid files:
text directory C:\Users\kyete\OneDrive\Documents\Backup\Annie Daniels Collection\spicxw\
comment Which tier of the TextGrid files should be used for segment analysis?
integer Tier 2
comment Which interval tier of the TextGrid files should be used for item names?
integer Item_tier 3
comment Full path of the resulting text file:
text resultfile RSrr.txt
comment Formant analysis options
integer Max_number_of_formants 5
positive Maximum_formant_(Hz) 5512.5
positive Window_length_(s) 0.025
endform

echo Files in directory 'directory$' will now be checked...
token = 0
filepair = 0
# this is a "safety margin" (in seconds) for formant analysis, in case the vowel segment is very short:
margin = 0.02325
lineNumber = 0

# Check if the result text file already exists. If it does, ask the user for permission to overwrite it.
if fileReadable (resultfile$) = 1
   pause The text file 'resultfile$' already exists. Do you want to continue and overwrite it?
filedelete 'resultfile$'
endif
# add the column titles to the text file:

titleLine$ ="midpoint	filename$	itemLabel$	itemIntervalNumber	1abel$	duration	spectralPeak1	spectralPeak2	spectralPeak3	segstart	segend	'newline$'"
fileappend 'resultfile$' 'titleLine$'



# Check the contents of the user-specified directory and open appropriate Sound and TextGrid pairs:
Create Strings as file list... list 'directory$'*
numberOfFiles = Get number of strings

printline The number of files found is 'numberOfFiles'.

#for loop to go through all files in the directory
for gridfile to numberOfFiles
   #printline gridfile 'gridfile'
   select Strings list
   gridfilename$ = Get string... gridfile
   #printline gridfilename is 'gridfilename$'

   #if statement to get texgrid files
   if right$ (gridfilename$, 9) = ".textgrid" or right$ (gridfilename$, 9) = ".TextGrid"  or right$ (gridfilename$, 9) = ".TEXTGRID"
      #printline This is a textgrid (ie, the if statement is yes)

      #check if there is a corresponding sound file if a textgrid file was found,
      filename$ = left$ (gridfilename$, (length (gridfilename$) - 9))
      #printline filename is 'filename$'
      #for to check for sound files
      for soundfile to numberOfFiles
         #printline soundfiles is 'soundfile' and number of files is 'numberOfFiles'
         soundfilename$ = Get string... soundfile
         #printline soundfilename is 'soundfilename$' and string is  'soundfile'
         #if statement to check if the left part of the filename is identical to left part of textgrid and if the extension is wav or aif
         if left$ (soundfilename$, (length (filename$))) = filename$ and (right$ (soundfilename$, (length (soundfilename$) - length (filename$))) = ".wav" or right$ (soundfilename$, (length (soundfilename$) - length (filename$))) = ".WAV" or right$ (soundfilename$, (length (soundfilename$) - length (filename$))) = ".aif" or right$ (soundfilename$, 5) = ".aiff" or right$ (soundfilename$, (length (soundfilename$) - length (filename$))) = ".AIF" or right$ (soundfilename$, (length (soundfilename$) - length (filename$))) = ".AIFF")
            printline This is a matching pair 'filename$'
            # open both files if they match
            #printline soundfile is 'directory$''soundfilename$' and texgrid file is 'directory$''soundfilename$'
            Read from file... 'directory$''soundfilename$'
            Read from file... 'directory$''gridfilename$'
            filepair = filepair + 1
            #get times for the segment

            #extract textgrid information
            call Measurements






            select Strings list

         #endif for finding matching sound file
         endif

      #endfor to get matching sound files
      endfor

   #endif for finding textgrid files
   endif

#endfor to go through all files in a directory
endfor

printline 'filepair' matching pairs of Sound and TextGrid files were found. 
printline The results were saved in 'resultfile$'.


select Strings list
Remove

#----------------------
procedure Measurements

# look at the TextGrid object
select TextGrid 'filename$'

filestart = Get starting time
fileend = Get finishing time

## get all intervals you want to measure
numberOfIntervals = Get number of intervals... tier

## small number of loops for debugging
#numberOfIntervals = 4

## get time info for the segment intervals
for interval to numberOfIntervals
	select TextGrid 'filename$'
	label$ = Get label of interval... tier interval



	segstart = Get starting point... tier interval
	segend = Get end point... tier interval
	midpoint = (segstart + segend)/2

	# get item label from tier 1
	itemIntervalNumber = Get interval at time... item_tier segstart
	itemLabel$ = Get label of interval... item_tier itemIntervalNumber

	
	duration = segend - segstart
	# Create a window for analyses (possibly adding the "safety margin"):
		windowstart = midpoint - 0.02325
		windowend = midpoint + 0.02325

	select Sound 'filename$'
	Extract part... windowstart windowend Hamming 1 yes
	Rename... extractedSegment
	select Sound extractedSegment
	To LPC (autocorrelation)... 22 0.0465 0.003 48.47
	To Spectrum (slice)... 0.0 21.51219 0.0 48.47

	#get frequency of maximum in hertz (convert to bark later)
	select Spectrum extractedSegment_0_0
	To Ltas (1-to-1)
	call SpectralPeakByPlace

	resultLine$ = "'midpoint'	'filename$'	'itemLabel$'	'itemIntervalNumber'	'label$'	'duration'	'spectralPeak1'	'spectralPeak2'	'spectralPeak3'	'segstart'	'segend''newline$'"
	#printline 'resultLine$'
	fileappend 'resultfile$' 'resultLine$'
	lineNumber = lineNumber + 1
	
	#make uniform Ltas for averaging and making pictures
	#if labelType = 4 & ( itemContext = 2 or itemContext = 0 or itemContext = 1) & (duration > 0.006)
	#if labelType = 4 & (duration > 0.006)
	#	select Sound extractedSegment
	#	To Ltas... 100
	#	Rename... 'itemLabel$''label$'
	#endif

	select Sound extractedSegment
	plus Spectrum extractedSegment_0_0
	plus Ltas extractedSegment_0_0
	plus LPC extractedSegment
	Remove
	

	
endfor

#pause Finished the root 'filename$' Do you want to stop?

endproc


##____________



#_------------------
procedure SpectralPeakByPlace

spectralPeak1 = 0
spectralPeak2 = 0
spectralPeak3 = 0

#it will do same ranges for all labels

	spectralPeak1 = Get frequency of maximum... 0 1200 Parabolic
	spectralPeak2 = Get frequency of maximum... 1200 2500 Parabolic
	spectralPeak3 = Get frequency of maximum... 2500 3900 Parabolic

#printline Analyzed segment 'itemContext' in window number 'spectralWindow1' and 'spectralWindow2'

endproc
