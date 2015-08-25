import sys, re, os
r1 = re.compile( ".*sounds::sound\(.*\);" )
r2 = re.compile( ".*play_variant_sound\(.*\);" )
r3 = re.compile( ".*play_ambient_variant_sound\(.*\);" )

# walkthrough all source file and check for code that plays sounds
def DumpSoundUsage( regex, path ):
    for root, dirs, files in os.walk( path ):
        for f in files:
            foundLines = []
            fileName = os.path.join( root, f )
            for l in open( fileName ):
                m = regex.match( l )
                if m:
                    foundLines.append( l.strip() )


            if len( foundLines ) > 0:
                print fileName
                for l in foundLines:
                    print "\t" + l

DumpSoundUsage( r1, sys.argv[1] )
DumpSoundUsage( r2, sys.argv[1] )
DumpSoundUsage( r3, sys.argv[1] )

