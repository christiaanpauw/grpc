#!/usr/bin/env Rscript

run_cmd <- function(cmd, args = character()) {
  path <- unname(Sys.which(cmd))
  if (!nzchar(path)) {
    return(list(
      path = NA_character_,
      status = NA_integer_,
      output = sprintf("Executable '%s' not found in PATH", cmd),
      executable = NA
    ))
  }
  cmd_args <- if (length(args) == 1L && length(grep("\\s", args, perl = TRUE)) == 1L) {
    strsplit(args, "\\s+", perl = TRUE)[[1]]
  } else {
    args
  }
  captured_warning <- NULL
  output <- tryCatch({
    withCallingHandlers(
      system2(path, cmd_args, stdout = TRUE, stderr = TRUE),
      warning = function(w) {
        captured_warning <<- conditionMessage(w)
        invokeRestart("muffleWarning")
      }
    )
  },
  error = function(e) {
    structure(paste("Error:", conditionMessage(e)), status = 1L)
  })
  status <- attr(output, "status")
  if (is.null(status)) {
    status <- 0L
  }
  output_text <- if (length(output) == 0L) "" else paste(output, collapse = "\n")
  if (!is.null(captured_warning) && nzchar(captured_warning)) {
    warning_text <- paste("Warning:", captured_warning)
    if (nzchar(output_text)) {
      output_text <- paste(output_text, warning_text, sep = "\n")
    } else {
      output_text <- warning_text
    }
  }
  is_exec <- tryCatch(
    file.access(path, 1L) == 0L,
    warning = function(...) NA,
    error = function(...) NA
  )
  list(path = path, status = status, output = output_text, executable = is_exec)
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

extract_library_dirs <- function(libs_output) {
  if (is.null(libs_output) || !nzchar(libs_output)) {
    return(character())
  }
  tokens <- unlist(strsplit(libs_output, "\\s+"))
  dirs <- tokens[startsWith(tokens, "-L")]
  dirs <- sub("^-L", "", dirs)
  unique(dirs[nzchar(dirs)])
}

extract_library_names <- function(libs_output) {
  if (is.null(libs_output) || !nzchar(libs_output)) {
    return(character())
  }
  tokens <- unlist(strsplit(libs_output, "\\s+"))
  libs <- tokens[startsWith(tokens, "-l")]
  libs <- sub("^-l", "", libs)
  unique(libs[nzchar(libs)])
}

locate_library_file <- function(lib_name, search_dirs) {
  candidates <- c(
    sprintf("lib%s.dylib", lib_name),
    sprintf("lib%s.so", lib_name),
    sprintf("lib%s.a", lib_name)
  )
  for (dir in search_dirs) {
    for (candidate in candidates) {
      path <- file.path(dir, candidate)
      if (file.exists(path)) {
        return(path)
      }
    }
  }
  NA_character_
}

check_library_architecture <- function(library_path, expected_arch) {
  if (!nzchar(library_path) || is.na(library_path)) {
    return(list(path = library_path, exists = FALSE, matches = NA, output = "Library not found"))
  }
  if (!file.exists(library_path)) {
    return(list(path = library_path, exists = FALSE, matches = NA, output = "Library not found"))
  }
  file_info <- run_cmd("file", library_path)
  matches <- NA
  if (!is.na(file_info$status) && file_info$status == 0L && nzchar(expected_arch)) {
    matches <- grepl(expected_arch, file_info$output, fixed = TRUE)
  }
  list(path = library_path, exists = TRUE, matches = matches, output = file_info$output, status = file_info$status)
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
      if (!is.na(res_help$status) && nzchar(res_help$output)) {
        res$output <- paste(res$output, res_help$output, sep = if (nzchar(res$output)) "\n" else "")
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
  headers_to_probe <- c(file.path("grpc", "grpc_security.h"),
                        file.path("grpc", "credentials.h"))
  header_checks <- lapply(headers_to_probe, function(header) {
    lapply(includes, check_header_for_symbol, header = header,
           symbol = "grpc_insecure_credentials_create")
  })
  header_checks <- unlist(header_checks, recursive = FALSE)
  diag$headers_to_probe <- headers_to_probe
  diag$header_checks <- header_checks
  diag$symbol_found <- any(vapply(header_checks, `[[`, logical(1), "has_symbol"))

  libs_res <- diag$pkg_config$grpc$libs
  libs_output <- if (!is.na(libs_res$status) && libs_res$status == 0L) libs_res$output else ""
  lib_dirs <- extract_library_dirs(libs_output)
  lib_names <- extract_library_names(libs_output)
  diag$library_dirs <- lib_dirs
  diag$library_names <- lib_names

  expected_arch <- diag$sys_info$machine
  library_arch_checks <- lapply(lib_names, function(lib) {
    path <- locate_library_file(lib, lib_dirs)
    check_library_architecture(path, expected_arch)
  })
  names(library_arch_checks) <- lib_names
  diag$library_architecture <- library_arch_checks

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
    cat("-", cmd, "\n  path:", ifelse(is.na(res$path), "<not found>", res$path),
        "\n  executable:", ifelse(is.na(res$executable), "<unknown>", res$executable),
        "\n  status:", res$status, "\n  output:\n")
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

  format_section("Library architecture inspection")
  if (length(diag$library_architecture) == 0L) {
    cat("No libraries were resolved from pkg-config output.\n")
  } else {
    cat("Expected architecture:", diag$sys_info$machine, "\n\n")
    for (lib in names(diag$library_architecture)) {
      check <- diag$library_architecture[[lib]]
      cat("Library:", lib, "\n")
      cat("  path:", ifelse(is.na(check$path), "<not found>", check$path), "\n")
      cat("  exists:", ifelse(isTRUE(check$exists), "TRUE", "FALSE"), "\n")
      if (!is.null(check$status)) {
        cat("  file status:", check$status, "\n")
      }
      cat("  matches expected architecture:", ifelse(is.na(check$matches), "<unknown>", check$matches), "\n")
      if (nzchar(check$output)) {
        cat("  file output:\n")
        cat(paste0("    ", strsplit(check$output, "\n", fixed = TRUE)[[1]], collapse = "\n"), "\n")
      }
      cat("\n")
    }
  }
  invisible(diag)
}

if (identical(environment(), globalenv()) && !interactive()) {
  result <- collect_grpc_diagnostics()
  print_grpc_diagnostics(result)
}
