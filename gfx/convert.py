import os, shutil, subprocess, re

regexNAME = re.compile( r'^NAME:(.*)' )
regexVIEW = re.compile( r'^VIEW:(.*)' )
regexWidth = re.compile( r'.*"width":\s*(\d+)' )
regexHeight = re.compile( r'.*"height":\s*(\d+)' )

def ConvertTileset( source, target, newName, newView, srcSize, dstSize, tileImage, fallbackImage ):
    newSize = "%f" % ( ( 100.0 * dstSize ) / srcSize )
    newSize = newSize + r"%x"
    newSize = newSize + "%f" % ( ( 100.0 * dstSize ) / srcSize )
    newSize = newSize + r"%"
    shutil.rmtree( target, True )
    shutil.copytree( source, target )
    subprocess.call( [ "convert", "-interpolate", "Nearest", "-filter", "point", "-resize", newSize, os.path.join( source, tileImage ), os.path.join( target, tileImage ) ] )
    if fallbackImage != "":
        subprocess.call( [ "convert", "-interpolate", "Nearest", "-filter", "point", "-resize", newSize, os.path.join( source, fallbackImage ), os.path.join( target, fallbackImage ) ] )

    oFile = open( os.path.join( target, "tileset_new.txt" ), "w" )
    for l in open( os.path.join( target, "tileset.txt" ) ):
        m1 = regexNAME.match( l )
        m2 = regexVIEW.match( l )
        if m1:
            print m1.group(1)
            oFile.writelines( l.replace( m1.group(1).lstrip(), newName ) )
        elif m2:
            oFile.writelines( l.replace( m2.group(1).lstrip(), newView ) )
        else:
            oFile.writelines( l )
    oFile.close()
    shutil.copyfile( os.path.join( target, "tileset_new.txt" ), os.path.join( target, "tileset.txt" ) )
    os.remove( os.path.join( target, "tileset_new.txt" ) )

    oFile = open( os.path.join( target, "tile_config_new.json" ), "w" )
    for l in open( os.path.join( target, "tile_config.json" ) ):
        m1 = regexWidth.match( l )
        m2 = regexHeight.match( l )
        if m1:
            oFile.writelines( l.replace( m1.group(1), str( dstSize ) ) )
        elif m2:
            oFile.writelines( l.replace( m2.group(1), str( dstSize ) ) )
        else:
            oFile.writelines( l )
    oFile.close()
    shutil.copyfile( os.path.join( target, "tile_config_new.json" ), os.path.join( target, "tile_config.json" ) )
    os.remove( os.path.join( target, "tile_config_new.json" ) )

if __name__ == "__main__":
    #ConvertTileset( "ChestHoleTileset", "ChestHoleTileset32", "ChestHole32", "ChestHole32", 24, 32, "tiles.png", "fallback.png" )
    ConvertTileset( "ChestHoleTileset", "ChestHoleTileset48", "ChestHole48", "ChestHole48", 24, 48, "tiles.png", "fallback.png" )
    #ConvertTileset( "MShock32Tileset", "MShock48Tileset", "MShock32", "MShock48", 32, 48, "tiles.png", "fallback.png" )
    #ConvertTileset( "MShock32TilesetModded", "MShock48TilesetModded", "MShock32Modded", "MShock48Modded", 32, 48, "tiles.png", "fallback.png" )
    #ConvertTileset( "BlockheadTileset", "BlockheadTileset48", "blockhead48", "Blockhead48's", 32, 48, "blockheadtiles.png", "" )
    #ConvertTileset( "DeonTileset", "DeonTileset48", "deon48", "Deon48's", 32, 48, "deontiles.png", "" )
    #ConvertTileset( "HoderTileset", "HoderTileset48", "hoder48", "Hoder48's", 32, 48, "hodertiles.png", "" )
    #ConvertTileset( "RetroASCIITileset", "RetroASCIITileset20", "retroascii20", "RetroASCII20", 10, 20, "retroasciitiles.png", "" )
    #ConvertTileset( "RetroASCIITileset", "RetroASCIITileset30", "retroascii30", "RetroASCII30", 10, 30, "retroasciitiles.png", "" )
    #ConvertTileset( "RetroDaysTileset20", "RetroDaysTileset30", "retrodays30", "RetroDays30px", 20, 30, "retrodaystiles20.png", "retrodaysfallback20.png" )
    #ConvertTileset( "ThuztorTileset@", "ThuztorTileset@32", "Boardgame-Style@32", "Thuztor'@32", 16, 32, "thuztortiles@.png", "" )
    #ConvertTileset( "TsuTileset", "TsuTileset32", "tsu32", "Tsu32's", 16, 32, "tsutiles.png", "" )
