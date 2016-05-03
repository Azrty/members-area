Parser = require 'jade/lib/parser'
p = require 'path'
fs = require 'fs'

viewDir = p.join(__dirname, "..", "views")

rootResolvePath = (path) ->
  path = p.join viewDir, path.substr(1)
  if path.indexOf(".") is -1
    path += ".jade"
  return path

oldResolvePath = Parser::resolvePath
Parser::resolvePath = (path, purpose) ->
  if path.charAt(0) is '!'
    return rootResolvePath(path)
  else
    attempt = oldResolvePath.apply this, arguments
    if fs.existsSync(attempt)
      return attempt
    else
      return rootResolvePath(path)
