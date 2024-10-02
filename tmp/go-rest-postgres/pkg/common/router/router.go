package router

import (
	"github.com/pauljamescleary/gomin/pkg/common/handler"

	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
)

func SetupRouter(handler *handler.Handler) *echo.Echo {
	e := echo.New()

	// Middleware
	e.Use(middleware.Logger())
	e.Use(middleware.Recover())

	// Routes
	e.GET("/action", handler.Action)
	e.GET("/users", handler.GetUsers)
	e.POST("/users", handler.CreateUser)
	e.GET("/users/:id", handler.GetUser)
	// e.PUT("/users/:id", handler.UpdateUser)
	// e.DELETE("/users/:id", handler.DeleteUser)
	return e
}
