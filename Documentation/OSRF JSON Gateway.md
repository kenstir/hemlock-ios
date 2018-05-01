# OSRF JSON Gateway

## Introduction

Hemlock is an app for library catalogs powered by [Evergreen](www.evergreen-ils.org).  Evergreen network services are provided by the Open Service Request Framework (OpenSRF or OSRF).  OSRF is [described elsewhere](https://evergreen-ils.org/opensrf-jabber-a-technical-review/), but for our purposes this much is sufficient:

* Hemlock calls OSRF through the JSON gateway, installed at path `/osrf-gateway-v1` on the catalog server
* Gateway requests take `service`, `method`, and zero or more `param` parameters.  All `param` parameters are JSON values.
* Gateway responses are JSON objects that usually require decoding.

## Gateway Requests

Here is a sample gateway request made to the open-ils.auth service and open-ils.auth.authenticate.init method:

```
POST /osrf-gateway-v1 HTTP/1.0

service=open-ils.auth&method=open-ils.auth.authenticate.init&param=%22joe_user%22
```

Note that param is a JSON string value and so is enclosed in quotes, encoded as `%22` .

A partial list of OSRF services (also called "applications"), methods, and params is [available online hosted on a demo Evergreen server](https://webby.evergreencatalog.com/opac/extras/docgen.xsl?service=open-ils.actor&param=%22retrieve%22&offset=0&limit=25).

## Gateway Responses

Gateway responses are JSON objects with `status` and `payload` keys.  The `payload` value is always an array.

```
# gateway response to open-ils.auth.authenticate.init
{"payload":["$2a$10$Bn.PWDb4nQonsRIkV/j9t."],"status":200}
```

Since the payload value is always an array, we'll take the first element and call it the "gateway response payload" or "payload" for short.

### Gateway response payload

The gateway response payload takes different forms.

#### JSON value

Examples of JSON value payloads

* open-ils.auth.authenticate.init payload
`"$2a$10$Bn.PWDb4nQonsRIkV/j9t."`

* open-ils.auth.authenticate.complete payload
`{"ilsevent":1000,"textcode":"LOGIN_FAILED","desc":"User login failed"}`

* open-ils.circ.holds.retrieve payload
`[]`

