Class dc.kubeless.REST Extends %CSP.REST
{

Parameter CONTENTTYPE = "application/json";

Parameter CHARSET = "UTF8";

XData UrlMap
{
<Routes>
   <Route Url="/healthz" Method="GET" Call="healthz"/>
   <Route Url="/metrics" Method="GET" Call="metrics"/>
   <Route Url="/([^/]+)" Method="GET" Call="work"/>
   <Route Url="/" Method="GET" Call="work"/>
   <Route Url="/([^/]+)" Method="POST" Call="work"/>
   <Route Url="/" Method="POST" Call="work"/>
 </Routes>
}

ClassMethod healthz() As %Status
{
  Write "OK"
  Quit $$$OK
}

ClassMethod metrics() As %Status
{
  set requests = []
  Set key = ""
  For {
    Set key = $ORDER(^dbg(key),-1)
    Quit:key=""

    set mime = {}
    set env = {}

    Set keyMime = ""
    For {
      Set keyMime = $ORDER(^dbg(key, "mime", keyMime))
      Quit:keyMime=""
      d mime.%Set(keyMime,^dbg(key, "mime", keyMime, 1))
    }

    Set keyEnv = ""
    For {
      Set keyEnv = $ORDER(^dbg(key, "env", keyEnv))
      Quit:keyEnv=""
      d env.%Set(keyEnv,$g(^dbg(key, "env", keyEnv)))
    }
    
    set request = {
      "arg": (^dbg(key, "arg")),
      "ts":(^dbg(key, "ts")),
      "url":(^dbg(key, "url")),
      "method":(^dbg(key, "method")),
      "body":($g(^dbg(key, "body"))),
      "mime":(mime),
      "env":(env)
    }

    do requests.%Push(request)
  }

  do requests.%ToJSON()
  Quit $$$OK
}

ClassMethod work(arg = "") As %Status
{
  #dim %request As %CSP.Request
  set i = $i(^dbg)
  set ^dbg(i, "arg") = arg
  set ^dbg(i, "ts") = $zdt($h,3,1)
  set ^dbg(i, "url") = %request.URL
  set ^dbg(i, "method") = %request.Method
  merge ^dbg(i, "data") = %request.Data
  merge ^dbg(i, "mime") = %request.MimeData
  merge ^dbg(i, "cgi") = %request.CgiEnvs

  if (%request.Content'="") {
    set body = %request.Content.Read($$$MaxStringLength)
  } elseif (%request.IsDefinedMimeData("CONTENT")) {
    set body = %request.GetMimeData("CONTENT").Read($$$MaxStringLength)
  }
  set ^dbg(i, "body") = $g(body)
  
  for env = "MOD_NAME","FUNC_HANDLER","FUNC_TIMEOUT","FUNC_PORT","KUBELESS_INSTALL_VOLUME" {
    set ^dbg(i, "env", env) = $SYSTEM.Util.GetEnviron(env)
  }

   if $d(body) {
    set event = {}.%FromJSON(body)
  } else {
    set event = {}
  }

  set context = {}

  set folder = ##class(%File).NormalizeDirectory($SYSTEM.Util.GetEnviron("KUBELESS_INSTALL_VOLUME"))
  set file = $SYSTEM.Util.GetEnviron("MOD_NAME")
  set class = $tr(file, "_", ".")
  
  if '##class(%Dictionary.CompiledClass).%ExistsId(class) {
    set sc = $SYSTEM.OBJ.Load(folder _ file _ ".cls", "cuks /checkuptodate=expandedonly /displaylog=0 /displayerror=0")
    if $$$ISERR(sc) {
      write {"error": ($System.Status.GetErrorText(sc))}.%ToJSON()
      quit $$$OK
    }
  }

  set method = $SYSTEM.Util.GetEnviron("FUNC_HANDLER")

  Quit $classmethod(class, method, event, context)
}

}
