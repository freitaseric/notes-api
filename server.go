package main

import (
	"log"
	"net/http"

	"github.com/freitaseric/api/internal/handlers"
	"github.com/freitaseric/api/internal/middlewares"
	"github.com/gin-gonic/gin"
)

var (
	Version   string
	Commit    string
	BuildDate string
)

func main() {
	apiHandler := handlers.NewHandler()

	versioningMiddleware := middlewares.NewVersioningMiddleware(Version)

	r := gin.Default()
	r.GET("/version", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"version":   Version,
			"commit":    Commit,
			"buildDate": BuildDate,
		})
	})

	v1 := r.Group("/" + Version)
	{
		v1.GET("/", apiHandler.Index)
	}

	r.NoRoute(versioningMiddleware.EnsureVersion())

	port := "8080"
	log.Printf("Server starting on port %s", port)
	log.Printf("App Version: %s, Commit: %s, Build Date: %s", Version, Commit, BuildDate)

	if err := r.Run(":" + port); err != nil {
		log.Fatalf("Server failed to start: %v", err)
	}
}
