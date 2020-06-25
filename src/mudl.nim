import jester

import htmlgen
import strutils
import uri
import threadpool
import strformat
import httpclient
import json
import osproc
import os

# TODO: use self-written downloaders

proc deezerSearchAlbum(artist, album: string): string =
  let url = &"https://api.deezer.com/search/album?q=artist:\"{artist.encodeUrl}\"%20album:\"{album.encodeUrl}\""
  let client = newHttpClient()
  let searchResult = parseJson client.getContent(url)
  if searchResult["data"].len > 0:
    return $searchResult["data"][0]["link"]
  
  

proc download(artist: string = "metallica", album: string = "ride the lightning", path = getCurrentDir()) =
  if execCmd("which deemix") != 0:
    quit("Please install deemix!")
  let url = deezerSearchAlbum(artist, album)
  if url != "":
    #let process = startProcess("deemix", workingDir = path, args = [&"--local", &"{url}"], options={poUsePath})
    echo url
  else:
    quit("Couldn't found this album on Deezer.")

proc server() =
  routes:
    get "/@artist/@album":
      let artist = decodeUrl @"artist"
      let album = decodeUrl @"album"
      spawn download(artist, album)
      resp r"<link rel=""stylesheet"" href=""https://unpkg.com/sakura.css/css/sakura.css"">" &
        h1("mudl") & p("Artist: " & artist) & p("Album: " & album) 


when isMainModule:
  import cligen
  clCfg.hTabCols = @[clOptKeys, clDescrip]
  dispatchMulti([download, short = { "album" : 'm' }], [server])
  