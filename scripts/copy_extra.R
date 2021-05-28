# branch <- system("git branch --show-current", intern = T)
# if (branch == "main")
#   dest_dir <- yaml::read_yaml("_bookdown.yml")$output_dir
# # otherwise, scripts/functions.R sets global dest_dir
# message(glue::glue("dest_dir: {dest_dir}"))

dir_out <- bookdown:::opts$get('output_dir')

paths_from <- c(
  "infographiq_example",
  "infographiq_example.zip")

paths_to <- fs::path(dir_out, paths_from)

for (i in 1:length(paths_to)){ # i = 2

  p_from <- paths_from[i]
  p_to   <- paths_to[i]

  p_is_dir    <- fs::is_dir(p_from)
  p_to_exists <- file.exists(p_to)

  if (!p_to_exists & p_is_dir)
    fs::dir_copy(p_from, p_to)

  if (!p_to_exists & !p_is_dir)
    fs::file_copy(p_from, p_to)
}


