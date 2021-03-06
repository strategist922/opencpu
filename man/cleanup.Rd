\name{cleanup}
\alias{cleanup}
\title{Clean up OpenCPU files from disk}
\usage{
  cleanup(what = c("tmp", "gist", "github", "cran", "bioc"),
    maxage = 10 * 60)
}
\arguments{
  \item{what}{What to clean up? Values correspond to API
  /ocpu/:what/}

  \item{maxage}{The maximum age (in seconds) for a
  directory to exempted from deletion.}
}
\description{
  OpenCPU stores a library with recent sessions and
  packages on disk. These files are stored in the temporary
  directory, so on most systems they are wiped on reboot.
  The cleanup function can be used to manually force
  removal of temporary files from disk.
}

