# pkgdown::deploy_to_branch()
# - source: https://github.com/r-lib/pkgdown/blob/aae5ce1adce646d180f29ede23210ef13527ac7c/R/deploy-site.R#L100-L147
deploy_bookdown <- function(
  bkd = ".", commit_message = construct_commit_message(bkd),
  clean = FALSE, branch = "gh-pages", remote = "origin", quiet = F,
  github_pages = (branch == "gh-pages"), ...){
  # source('scripts/functions.R')
  # list2env(
  #   list(
  #     bkd = ".", commit_message = construct_commit_message(bkd),
  #     clean = FALSE, branch = "gh-pages", remote = "origin",
  #     github_pages = T),
  #   envir = globalenv())

  if (!require(librarian)){
    install.packages("librarian")
    library(librarian)
  }
  shelf(
    fs)

  dest_dir <- fs::dir_create(fs::file_temp())
  on.exit(fs::dir_delete(dest_dir))
  if (!git_has_remote_branch(remote, branch)) {
    old_branch <- git_current_branch()
    git("checkout", "--orphan", branch)
    git("rm", "-rf", "--quiet", ".")
    git("commit", "--allow-empty", "-m", sprintf("Initializing %s branch",
                                                 branch))
    git("push", remote, paste0("HEAD:", branch))
    git("checkout", old_branch)
  }
  git("remote", "set-branches", remote, branch)
  git("fetch", remote, branch)
  github_worktree_add(dest_dir, remote, branch)
  on.exit(github_worktree_remove(dest_dir), add = TRUE)
  #pkg -> bkd <- as_pkgdown(pkg, override = list(destination = dest_dir))
  if (clean) {
    rule("Cleaning files from old book", line = 1)
    clean_book(bkd)
  }
  build_site(pkg, devel = FALSE, preview = FALSE, install = FALSE,
             ...)
  if (github_pages) {
    #build_github_pages(pkg)
    bookdown::render_book(quiet = quiet)
  }
  github_push(dest_dir, commit_message, remote, branch)
  invisible()
}

git_has_remote_branch <- function(remote, branch) {
  has_remote_branch <- git("ls-remote", "--quiet", "--exit-code", remote, branch, echo = FALSE, echo_cmd = FALSE, error_on_status = FALSE)$status == 0
}
git_current_branch <- function() {
  branch <- git("rev-parse", "--abbrev-ref", "HEAD", echo = FALSE, echo_cmd = FALSE)$stdout
  sub("\n$", "", branch)
}

github_worktree_add <- function(dir, remote, branch) {
  rule("Adding worktree", line = 1)
  git("worktree",
      "add",
      "--track", "-B", branch,
      dir,
      paste0(remote, "/", branch)
  )
}

github_worktree_remove <- function(dir) {
  rule("Removing worktree", line = 1)
  git("worktree", "remove", dir)
}

github_push <- function(dir, commit_message, remote, branch) {
  # force execution before changing working directory
  force(commit_message)

  rule("Commiting updated site", line = 1)

  with_dir(dir, {
    git("add", "-A", ".")
    git("commit", "--allow-empty", "-m", commit_message)

    rule("Deploying to GitHub Pages", line = 1)
    git("remote", "-v")
    git("push", "--force", remote, paste0("HEAD:", branch))
  })
}

git <- function(..., echo_cmd = TRUE, echo = TRUE, error_on_status = TRUE) {
  callr::run("git", c(...), echo_cmd = echo_cmd, echo = echo, error_on_status = error_on_status)
}

construct_commit_message <- function(bkd, commit = ci_commit_sha()) {
  #pkg <- as_pkgdown(pkg)
  #sprintf("Built site for %s: %s@%s", pkg$package, pkg$version, substr(commit, 1, 7))
  bkd <- basename(normalizePath("."))
  sprintf("Built site for %s: @%s", bkd, substr(commit, 1, 7))
}

ci_commit_sha <- function() {
  env_vars <- c(
    # https://docs.travis-ci.com/user/environment-variables/#default-environment-variables
    "TRAVIS_COMMIT",
    # https://help.github.com/en/actions/configuring-and-managing-workflows/using-environment-variables#default-environment-variables
    "GITHUB_SHA"
  )

  for (var in env_vars) {
    commit_sha <- Sys.getenv(var, "")
    if (commit_sha != "")
      return(commit_sha)
  }

  ""
}
