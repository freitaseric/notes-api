package middlewares

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

var globalPaths = map[string]bool{
	"/":        true,
	"/version": true,
}

type VersioningMiddleware struct {
	ApiVersion string
}

func NewVersioningMiddleware(appVersion string) *VersioningMiddleware {
	return &VersioningMiddleware{
		ApiVersion: appVersion,
	}
}

func (m *VersioningMiddleware) EnsureVersion() gin.HandlerFunc {
	return func(c *gin.Context) {
		requestedPath := c.Request.URL.Path
		method := c.Request.Method

		if globalPaths[requestedPath] {
			c.JSON(http.StatusMethodNotAllowed, gin.H{
				"error":  "Method not allowed for this endpoint",
				"path":   requestedPath,
				"method": method,
			})
			return
		}

		newPath := "/" + m.ApiVersion + requestedPath
		c.Redirect(http.StatusPermanentRedirect, newPath)

		c.Abort()
	}
}
