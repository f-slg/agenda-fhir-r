transaction_entry <- function(resource, method, url) list(resource=resource,request=list(method=toupper(method),url=url))
make_transaction_bundle <- function(entries,id=new_id("bundle")) c(base_resource("Bundle",id),list(type="transaction",entry=entries))
