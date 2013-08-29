JSONP = (url, method, callback) ->
  url = url or ''
  method = method or ''
  callback = callback or ->

  if typeof method is 'function'
    callback = method
    method = 'callback'

  Math.round(Math.random() * 1000001)
  generatedFunction = 'jsonp' +

  window[generatedFunction] = (json) ->
    callback json
    delete window[generatedFunction]

  if url.indexOf '?' is -1
    url = url + '?'
  else
    url = url + '&'

  jsonpScript = document.createElement 'script'
  jsonpScript.setAttribute 'src', "#{url}#{method}=#{generatedFunction}"
  document.getElementsByTagName('head')[0].appendChild jsonpScript