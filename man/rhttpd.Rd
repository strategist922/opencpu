\docType{data}
\name{rhttpd}
\alias{rhttpd}
\title{The Rhttpd based single-user OpenCPU server.}
\format{Control object}
\description{
  The Rhttpd, a.k.a "Dynamic Help Server" provides an
  alternative http server in case httpuv is not available
  (e.g. due to firewall restrictions). Currently, two
  different implementations of Rhttpd exist: a simple
  built-in version in R (\code{\link{startDynamicHelp}}),
  and a reimplementation which is part of rstudio-server
  (not rstudio-desktop).
}
\details{
  The performance and reliability of the built-in Rhttpd
  varies a lot, especially on Windows. When possible, it is
  recommended to avoid this and use the httpuv based
  OpenCPU server instead (see \code{\link{opencpu}}). The
  rstudio-server implementation of Rhttpd seems a bit
  better. Another disadvantage is that Rhttpd runs in the
  currrent process and will block the session during http
  requests.

  When hosted using the Rhttpd, OpenCPU is API is mounted
  under the \url{/custom/ocpu/} url. For example:
  \url{http://localhost:8787/custom/ocpu/library/stats}.
}
\examples{
\dontrun{
rhttpd$init()
rhttpd$url()
rhttpd$browse('/library/stats/man/glm')
}
}
\references{
  \url{http://www.opencpu.org}
}
\seealso{
  Other opencpu: \code{\link{opencpu}}
}
\keyword{datasets}

