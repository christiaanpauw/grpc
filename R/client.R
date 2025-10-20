#' Build a client handle
#' 
#' @param impl the service stub definitions generated from the proto
#' @param channel what to connect to
#' @return client handle
#' @importFrom RProtoBuf P serialize read new
#' @export
grpc_client <- function(impl, channel) {
  
  
  client_functions <- lapply(impl, function(fn)
    {
      RequestDescriptor <- P(fn[["RequestType"]]$proto)
      ResponseDescriptor <- P(fn[["ResponseType"]]$proto)
      
      list(
        call = function(x, metadata=character(0)) read(ResponseDescriptor, fetch(channel, fn$name, serialize(x, NULL), metadata)),
        build = function(...) new(RequestDescriptor, ...)
      )
    })
  
  
  
  client_functions
}
