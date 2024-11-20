package flags

import (
	"github.com/urfave/cli/v2"
)

var (
	MongoUriFlag = &cli.StringFlag{
		Name:     "mongo-uri",
		Usage:    "Connection string to MongoDB",
		EnvVars:  []string{"MONGO_URI"},
		Required: true,
	}
	SupportedChainsFlag = &cli.StringSliceFlag{
		Name:     "supported-chains",
		Usage:    "Comma separated list of supported chains",
		Value:    cli.NewStringSlice("421614"),
		EnvVars:  []string{"SUPPORTED_CHAINS"},
		Required: false,
	}
)

// Flags contains the list of configuration options available to the binary.
var Flags = []cli.Flag{MongoUriFlag, SupportedChainsFlag}
