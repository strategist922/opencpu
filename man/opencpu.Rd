\docType{data}
\name{opencpu}
\alias{opencpu}
\title{The httpuv based single-user OpenCPU server.}
\format{Control object}
\description{
  This object controls the httpuv based OpenCPU server.
  This is the preferred method of running OpenCPU inside an
  R session. The server runs in a parallel process and does
  not interact with the current session.
}
\details{
  Note that this is a single user server; i.e. for local
  use only. Because R is single-threaded, the single-user
  server has no support for concurrent http requests (but
  httpuv does a nice job queueing them). Also there are no
  security restrictions being enforced, as is the case for
  the OpenCPU cloud server.

  The OpenCPU server will automatically be started when the
  OpenCPU packge is attached. By default, the server starts
  at a random port and the API will be available under the
  /ocpu path. For example:
  \url{http://localhost:12345/ocpu/library/stats}.

  Once apps are working on the local OpenCPU server, they
  can easily be published using the OpenCPU cloud server.
  The cloud server does have support for concurrent
  requests, security policies and caching mechanisms to
  boost performance.
}
\examples{
\dontrun{
opencpu$start(12345);
opencpu$restart()
opencpu$url()
opencpu$browse('library/stats/man/glm')
opencpu$stop()
}
}
\references{
  \url{http://www.opencpu.org}
}
\seealso{
  Other opencpu: \code{\link{rhttpd}}
}
\keyword{datasets}

