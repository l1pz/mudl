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
import strformat

# TODO: use self-written downloaders

proc deezerSearchAlbum(artist, album: string): string =
  let url = &"https://api.deezer.com/search/album?q=artist:\"{artist.encodeUrl}\"%20album:\"{album.encodeUrl}\""
  let client = newHttpClient()
  let searchResult = parseJson client.getContent(url)
  client.close()
  if searchResult["data"].len > 0:
    return searchResult["data"][0]["link"].to(string)

proc deezerNumberOfTracks(url: string): int = 
  let client = newHttpClient()
  let apiResult = parseJson client.getContent(url.replace("www.", "api."))
  client.close()
  return apiResult["nb_tracks"].to(int)

proc deezerDownload(url, path: string): string =
  let nTracks = deezerNumberOfTracks(url)

  let process = startProcess("deemix", workingDir = path, args = [&"--local", &"{url}"], options={poUsePath, poStdErrToStdOut})
  let output = process.outputStream
  var line: string
  
  echo "Starting download!"
  var bar = newProgressBar(nTracks)
  bar.start()

  while process.peekExitCode == -1:
    if output.readLine(line):
      if result == "":
        result = line
        result.removePrefix("INFO:deemix:Using a local download folder: ")
      if line.contains("Track download completed"):
        bar.increment()
  
  bar.finish()
  process.close()
  echo &"Finished download! - {nTracks} downloaded"

proc deezerCleanupDirs(directoryName, path: string) =
  let absPath = if path.isAbsolute: path else: path.absolutePath
  for file in walkDir(absPath / directoryName):
    let fileNewPath = absPath / file.path.splitPath.tail
    if file.kind == pcDir:
      removeDir(fileNewPath)
      moveDir(file.path, fileNewPath)
  removeDir(absPath / directoryName)

proc download(artist: string, album: string, path = getCurrentDir()) =
  if execCmdEx("which deemix").exitCode != 0:
    echo("Please install deemix!")
    return
  let url = deezerSearchAlbum(artist, album)
  if url != "":
    let directoryName = deezerDownload(url, path)
    deezerCleanupDirs(directoryName, path)
      
  else:
    echo("Couldn't found this album on Deezer.")
    return

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
  