import jester
import progress

import htmlgen
import strutils
import uri
import threadpool
import strformat
import httpclient
import json
import osproc
import os
import streams

# TODO: use self-written downloaders

proc deezerSearchAlbum(artist, album: string): string =
  let url = &"https://api.deezer.com/search/album?q=artist:\"{artist.encodeUrl}\"%20album:\"{album.encodeUrl}\""
  let client = newHttpClient()
  let searchResult = parseJson client.getContent(url)
  client.close()
  if searchResult["data"].len > 0:
    return searchResult["data"][0]["link"].to(string)

proc deezerNumberOfTracks(url: string): int = 
  echo url
  let client = newHttpClient()
  let apiResult = parseJson client.getContent(url.replace("www.", "api."))
  client.close()
  return apiResult["nb_tracks"].to(int)
  
  

proc download(artist: string = "metallica", album: string = "ride the lightning", path = getCurrentDir()) =
  if execCmd("which deemix") != 0:
    quit("Please install deemix!")
  let url = deezerSearchAlbum(artist, album)
  if url != "":
    let nTracks = deezerNumberOfTracks(url)
    var bar = newProgressBar(nTracks)
    bar.start()
    let process = startProcess("deemix", workingDir = path, args = [&"", &"{url}"], options={poUsePath, poStdErrToStdOut})
    let output = process.outputStream
    var line: string
    while true:
      if output.readLine(line):
        if line.contains("Track download completed"):
          bar.increment
      else:
        if process.peekExitCode != -1: break
    process.close
    bar.finish()

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
  