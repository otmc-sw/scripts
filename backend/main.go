package main

import (
	"github.com/otmc-sw/logger"
	rest "github.com/otmc-sw/rest"
)

func main() {
	logger.New()
	rest.Debug(true)
}
