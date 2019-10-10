The cstore and pcrud methods are all generated from the IDL at service
startup.  If you know how cstore works, then you pretty much know how
pcrud works.  You create, retrieve, update, and delete things in pretty
much the same way.  The main differences being in the method names
(pcurd uses the IDL class id, and cstore uses the Fieldmapper class id
with :: turned into _) and in pcrud pretty much always requiring
permissions, so therefore an authtoken.  Also, cstore should *never* be
exposed through the gateway.

The method names are totally predictable when you understand how they
are generated. For ccvm, we get:

open-ils.pcrud.ccvm.create
open-ils.pcrud.ccvm.retrieve
open-ils.pcrud.ccvm.update
open-ils.pcrud.ccvm.delete
open-ils.pcrud.ccvm.search
open-ils.pcrud.ccvm.id_list

create takes a newly made Fieldmapper object
retrieve takes an integer of the database id
update takes an existing Fieldmapper object
delete takes an existing Fieldmapper object
search takes a JSON object of search parameters
id_list takes a JSON object of search parameters

The arguments all come after the authtoken.

Create, update, and delete, all have to happen within a pcrud
transaction or you will get an error message.

If you know C, you can find how this is done, along with a somewhat
helpful comment beginning around line 51 in
Evergreen/Open-ILS/src/c-apps/oils_pcrud.c.

-- 
Jason Stephenson