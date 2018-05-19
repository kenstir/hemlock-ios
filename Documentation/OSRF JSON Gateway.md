# OSRF JSON Gateway

## Introduction

Hemlock is an app for library catalogs powered by [Evergreen](www.evergreen-ils.org).  Evergreen network services are provided by the Open Service Request Framework (OpenSRF or OSRF).  OSRF itself is [described elsewhere](https://evergreen-ils.org/opensrf-jabber-a-technical-review/), but for our purposes this much is sufficient:

* Hemlock calls OSRF through the JSON gateway, installed at path `/osrf-gateway-v1` on the catalog server
* Gateway requests take `service`, `method`, and zero or more `param` parameters.  `service` and `method` parameters are strings, `param` parameters are JSON values.
* Gateway responses are JSON values.  Sometimes they are plain JSON values that can be used directly, but usually they contain OSRF objects encoded in "wire protocol" that require decoding.

## Gateway Requests

Here is a sample gateway request made to the open-ils.auth service and open-ils.auth.authenticate.init method:

```
POST /osrf-gateway-v1 HTTP/1.0

service=open-ils.auth&method=open-ils.auth.authenticate.init&param=%22joe_user%22
```

Note that param is a JSON string value and so is enclosed in quotes, encoded as `%22` .

A partial list of OSRF services (also called "applications"), methods, and params is [hosted on a demo Evergreen server](https://webby.evergreencatalog.com/opac/extras/docgen.xsl?service=open-ils.actor&param=%22retrieve%22&offset=0&limit=25).

## Gateway Responses

Gateway responses are JSON objects with `status` and `payload` keys.  The `payload` value is always an array.

open-ils.auth.authenticate.init gateway response
```
{"payload":["$2a$10$Bn.PWDb4nQonsRIkV/j9t."],"status":200}
```

Since the payload value is always an array, we take the first element and call it the "gateway response payload" or "payload" for short.

### Gateway response payload types

The gateway response payload takes different forms.

#### JSON value

A gateway response payload may be a plain JSON value.

open-ils.auth.authenticate.init payload: string
```
"$2a$10$Bn.PWDb4nQonsRIkV/j9t."
```

open-ils.auth.authenticate.complete payload: object
```
{"ilsevent":1000,"textcode":"LOGIN_FAILED","desc":"User login failed"}
```

open-ils.circ.holds.retrieve payload: array
```
[]
```

#### Encoded OSRF object

A gateway response payload may be an encoded OSRF object, which is an Evergreen object encoded in "wire format".

open-ils.circ.retrieve payload: an encoded OSRF "circ" object
```
{"__c":"circ","__p":[null,null,null,69,3788,"f","2018-05-02T23:59:59-0400","7 days","7_days_1_renew","1 day",73493047,"3.00","default","f","f","0.00","0_cent",1,"00:00:00",null,null,17124983,409071,null,"2018-04-25T17:05:08-0400","2018-04-25T17:05:08-0400",1720,null,null,null,null,null,null,null,null,null,null,323]}
```

This circ object cannot be reconstructed without access to the interface definition language (IDL), which describes the order of the fields, and their names.  The IDL is available from the catalog server at the path `/reports/fm_IDL.xml`.  The full IDL is huge, so there is a significant performance gain to be had by parsing only the subset describing the classes we are interested in, e.g. `fm_IDL.xml?class=aout&class=circ` 

#### Collection of OSRF objects

A gateway response payload may be an arbitrarily complex collection of OSRF objects, e.g. an array of "circ" (Circulation) objects or a tree of "aou" (Organizational Unit) objects.  For an example of a nested collection, visit `/osrf-gateway-v1?service=open-ils.actor&method=open-ils.actor.org_tree.retrieve`

