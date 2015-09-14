import os, subprocess

for root, dirs, files in os.walk( "./" ):
    for f in files:
        print os.path.join( root, f )
        iFile = os.path.join( root, f )
        oFile = os.path.splitext( os.path.join( root, f ) )[0] + ".wav"

        print oFile
        #if os.path.splitext( os.path.join( root, f ) )[1] in [ ".ogg", ".OGG" ]:
        #    subprocess.call( [ "sox", iFile, "-r", "22050", "-e", "signed", "-c", "2", "-b", "16", oFile  ] )
        if os.path.splitext( os.path.join( root, f ) )[1] in [ ".ogg", ".OGG", ".mp3", ".mp3" ]:
            os.remove( os.path.join( root, f ) )

