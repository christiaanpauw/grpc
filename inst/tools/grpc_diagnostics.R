#!/usr/bin/env Rscript

run_cmd <- function(cmd, args) {
  path <- unname(Sys.which(cmd))
  if (!nzchar(path)) {
    return(list(path = NA_character_, status = NA_integer_, output = sprintf("Executable '%s' not found in PATH", cmd)))
  }
  output <- tryCatch(
    system2(path, args, stdout = TRUE, stderr = TRUE),
    warning = function(w) {
      structure(paste("Warning:", conditionMessage(w)), status = 1L)
    },
    error = function(e) {
      structure(paste("Error:", conditionMessage(e)), status = 1L)
    }
  )
  status <- attr(output, "status")
  if (is.null(status)) {
    status <- 0L
  }
  list(path = path, status = status, output = paste(output, collapse = "\n"))
}

extract_include_dirs <- function(cflags_output) {
  if (is.null(cflags_output) || !nzchar(cflags_output)) {
    return(character())
  }
  tokens <- unlist(strsplit(cflags_output, "\\s+"))
  includes <- tokens[startsWith(tokens, "-I")]
  includes <- sub("^-I", "", includes)
  includes[nzchar(includes)]
}

check_header_for_symbol <- function(include_dir, header, symbol) {
  path <- file.path(include_dir, header)
  if (!file.exists(path)) {
    return(list(include_dir = include_dir, path = path, exists = FALSE, has_symbol = FALSE, error = "Header not found"))
  }
  lines <- tryCatch(readLines(path, warn = FALSE), error = function(e) e)
  if (inherits(lines, "error")) {
    return(list(include_dir = include_dir, path = path, exists = TRUE, has_symbol = FALSE, error = conditionMessage(lines)))
  }
  list(include_dir = include_dir, path = path, exists = TRUE, has_symbol = any(grepl(symbol, lines, fixed = TRUE)), error = NULL)
}

collect_grpc_diagnostics <- function() {
  diag <- list()
  diag$timestamp <- format(Sys.time(), tz = "UTC")
  diag$sys_info <- as.list(Sys.info())
  diag$r_version <- list(
    version = R.version$version.string,
    platform = R.version$platform
  )
  diag$env <- as.list(Sys.getenv(c("PKG_CONFIG_PATH", "GRPC_INSTALL_DIR", "GRPC_HOME"), unset = NA_character_))

  executables <- c("pkg-config", "protoc", "grpc_cpp_plugin")
  diag$executables <- lapply(executables, function(cmd) {
    res <- run_cmd(cmd, "--version")
    if (!is.na(res$status) && res$status != 0L && cmd == "grpc_cpp_plugin") {
      # try --help to capture version banner for plugins without --version
      res_help <- run_cmd(cmd, "--help")
      if (!is.na(res_help$status)) {
        res$output <- paste(res$output, res_help$output, sep = "\n")
      }
    }
    res
  })
  names(diag$executables) <- executables

  pkg_targets <- c("grpc", "grpc++")
  diag$pkg_config <- lapply(pkg_targets, function(pkg) {
    list(
      modversion = run_cmd("pkg-config", c("--modversion", pkg)),
      libs = run_cmd("pkg-config", c("--libs", pkg)),
      cflags = run_cmd("pkg-config", c("--cflags", pkg))
    )
  })
  names(diag$pkg_config) <- pkg_targets

  cflags_res <- diag$pkg_config$grpc$cflags
  cflags_output <- if (!is.na(cflags_res$status) && cflags_res$status == 0L) cflags_res$output else ""
  includes <- extract_include_dirs(cflags_output)
  diag$include_dirs <- includes
  header_checks <- lapply(includes, check_header_for_symbol, header = file.path("grpc", "grpc_security.h"), symbol = "grpc_insecure_credentials_create")
  diag$header_checks <- header_checks
  diag$symbol_found <- any(vapply(header_checks, `[[`, logical(1), "has_symbol"))

  diag
}

format_section <- function(title) {
  cat(title, "\n", strrep("-", nchar(title)), "\n", sep = "")
}

print_grpc_diagnostics <- function(diag) {
  format_section("gRPC build diagnostics")
  cat("Timestamp:", diag$timestamp, "(UTC)\n\n")

  format_section("System information")
  print(diag$sys_info)
  cat("\nR version:\n")
  print(diag$r_version)
  cat("\n")

  format_section("Environment variables")
  env_df <- data.frame(variable = names(diag$env), value = unlist(diag$env), row.names = NULL, stringsAsFactors = FALSE)
  print(env_df)
  cat("\n")

  format_section("Executable discovery")
  for (cmd in names(diag$executables)) {
    res <- diag$executables[[cmd]]
    cat("-", cmd, "\n  path:", ifelse(is.na(res$path), "<not found>", res$path), "\n  status:", res$status, "\n  output:\n")
    cat(paste0("    ", strsplit(res$output, "\n", fixed = TRUE)[[1]], collapse = "\n"), "\n\n", sep = "")
  }

  format_section("pkg-config results")
  for (pkg in names(diag$pkg_config)) {
    cat("Package:", pkg, "\n")
    for (field in c("modversion", "libs", "cflags")) {
      res <- diag$pkg_config[[pkg]][[field]]
      cat("  ", field, ":\n", sep = "")
      cat("    status:", res$status, "\n")
      cat("    output:\n")
      cat(paste0("      ", strsplit(res$output, "\n", fixed = TRUE)[[1]], collapse = "\n"), "\n")
    }
    cat("\n")
  }

  format_section("Header inspection")
  if (length(diag$include_dirs) == 0L) {
    cat("No include directories were found in pkg-config cflags output.\n")
  } else {
    cat("Include directories from pkg-config:\n")
    for (dir in diag$include_dirs) {
      cat(" -", dir, "\n")
    }
    cat("\n")
    for (check in diag$header_checks) {
      cat("Header:", check$path, "\n")
      cat("  exists:", check$exists, "\n")
      cat("  has grpc_insecure_credentials_create:", check$has_symbol, "\n")
      if (!is.null(check$error)) {
        cat("  note:", check$error, "\n")
      }
      cat("\n")
    }
  }
  cat("Symbol 'grpc_insecure_credentials_create' available:", diag$symbol_found, "\n")
  invisible(diag)
}

if (identical(environment(), globalenv()) && !interactive()) {
  result <- collect_grpc_diagnostics()
  print_grpc_diagnostics(result)
}
