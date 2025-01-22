#!/bin/ksh

#  Return random string of letters in any case and/or digits.
#  Input is a format string denoting format and length to return.
#  Additionally, input may include format string of characters to exclude.
#
#  If no format is given, return format is set to CAAANA
#  The randchar(TYPE) function can take one of the following values to define the returned byte:
#  "C" or "c" for any alpha character,
#  "U" for upper case alpha character,
#  "u" for upper case alpha character or numeric,
#  "L" for lower case alpha character,
#  "l" for lower case alpha character or numeric,
#  "N" or "n" for numeric,
#  "A" (or none) for any.
#
#
# Example:
#          get_random_key.ksh CAAANA oldp1w
#
#          The above returns the following:
#          C - any alpha chraracter
#          A - any alpha or numeric character
#          A - any alpha or numeric character
#	   A - any alpha or numeric character
#          N - numeric character
#          A - any alpha or numeric character
#
#          From the above samples, do not include the values
#          oldp1w (case insensitive) in the return string.
#
# Author Pete Lerner - 6/20/2005

# Set to input parameter format string.
PASSFMT="$1"

# If input format string omitted, assign a default format string.
if [[ -z "$PASSFMT" ]] then
     PASSFMT="CNAAAAAA"
fi

# Shift the shell input parameters
shift

# Read in the remaining input parameter(s) as the characters to exclude from the output.
SKIPCHARS="$*"

echo "$PASSFMT $SKIPCHARS" | /bin/nawk '
function randchar(TYPE) {

	if ( TYPE == "C" ) { STRNG = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"; SRCHLNGTH = 52 }
	else if ( TYPE == "c" ) { STRNG = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"; SRCHLNGTH = 52 }
	else if ( TYPE == "U" ) { STRNG = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"; SRCHLNGTH = 26 }
	else if ( TYPE == "u" ) { STRNG = "1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ"; SRCHLNGTH = 36 }
	else if ( TYPE == "L" ) { STRNG = "abcdefghijklmnopqrstuvwxyz"; SRCHLNGTH = 26 }
	else if ( TYPE == "l" ) { STRNG = "1234567890abcdefghijklmnopqrstuvwxyz"; SRCHLNGTH = 36 }
	else if ( TYPE == "N" ) { STRNG = "1234567890"; SRCHLNGTH = 10 }
	else if ( TYPE == "n" ) { STRNG = "1234567890"; SRCHLNGTH = 10 }
	else { STRNG = "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"; SRCHLNGTH = 62 }

	return substr(STRNG, int(SRCHLNGTH * rand() + 1), 1)
}

BEGIN { FS="" }
{	SPBYTE = index($1, " ")
	FMTSTR = substr($1,1,SPBYTE-1)
	SKIPCHARS = toupper(substr($1,SPBYTE+1))
	SKIPCHARS = SKIPCHARS tolower(SKIPCHARS)
	srand()
	i = 0
	while ( i < length(FMTSTR) )
		{ 
		++i; 
		NEXTBYTE = randchar(substr(FMTSTR,i,1)) 
		c = 0
		while ( (index(SKIPCHARS toupper(NEWPASS) tolower(NEWPASS),NEXTBYTE) != 0 ) && (c < 25*length(FMTSTR)) )
			{ ++c;
			  NEXTBYTE = randchar(substr(FMTSTR,i,1))
			if ( c == 25*length(FMTSTR)) { print "Unable to calculate string that matches format and prohibited characters."; exit 1 }
			}
		NEWPASS = NEWPASS NEXTBYTE 
		}

	print NEWPASS
	exit
} '

