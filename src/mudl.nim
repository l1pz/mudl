import jester
import htmlgen
import strutils
import uri
import threadpool
import strformat
import httpclient
import json
import osproc

# TODO: use self-written deezer downloader

proc albumSearchQuery(artist, album: string): string =
  &"https://api.deezer.com/search/album?q=artist:\"{artist.encodeUrl}\"%20album:\"{album.encodeUrl}\""
  

proc download(artist: string = "metallica", album: string = "ride the lightning") =
  let client = newHttpClient()
  let result = parseJson client.getContent(albumSearchQuery(artist, album))
  if result["data"].len > 0:
    let link = result["data"][0]["link"]

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
  