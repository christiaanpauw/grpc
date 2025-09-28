#' Collect build diagnostics for the grpc package
#'
#' @return A list containing diagnostic information about the local gRPC toolchain.
#'   The information is also printed as a side-effect.
#' @examples
#' \donttest{
#'   diagnostics <- grpc_diagnostics()
#' }
#' @export
grpc_diagnostics <- function() {
  tool_path <- system.file("tools", "grpc_diagnostics.R", package = "grpc")
  if (!nzchar(tool_path)) {
    stop("Unable to locate diagnostic helper in installed package.")
  }
  env <- new.env(parent = baseenv())
  sys.source(tool_path, envir = env)
  collector <- get("collect_grpc_diagnostics", envir = env, inherits = FALSE)
  printer <- get("print_grpc_diagnostics", envir = env, inherits = FALSE)
  result <- collector()
  printer(result)
  invisible(result)
}
