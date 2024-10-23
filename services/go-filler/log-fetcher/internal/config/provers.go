package config

type Prover int

const (
	NilProver Prover = iota
	ArbitrumProver
	OPStackProver
)

var proverName = map[Prover]string{
	NilProver:      "None",
	ArbitrumProver: "ArbitrumProver",
	OPStackProver:  "OPStackProver",
}

func (ss Prover) String() string {
	return proverName[ss]
}
