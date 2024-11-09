package main

import (
	"fmt"
	"notification-app/config"
	"notification-app/db"
	"notification-app/routes"
	"os"
)

func main() {
	err := config.EnvSetup()
	if err != nil {
		fmt.Printf("Error setting up environment: %v\n", err)
		return
	}
	fmt.Println("Environment variables loaded successfully")
	fmt.Printf("Current environment: %s\n", os.Getenv("GO_ENV"))
	err2 := db.DatabaseInit()
	if err2 != nil {
		fmt.Printf("Error in connecting to db: %v\n", err2)
		return
	}
	fmt.Println("DB successfully connected", os.Getenv("POSTGRES_DB"))

	//db.Migrate()

	r := routes.SetupRouter()

	port := os.Getenv("PORT")
	if port == "" {
		port = "3000" // default to 3000 if PORT is not set
	}

	r.Run(fmt.Sprintf(":%s", port))
	//running
}
