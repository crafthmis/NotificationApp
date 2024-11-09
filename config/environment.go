package config

type Config struct {
	Development envkey `json:"development"`
	Production  envkey `json:"production"`
}

type envkey map[string]string
