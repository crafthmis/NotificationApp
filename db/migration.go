package db

import (
	"errors"
	"notification-app/models"
)

func Migrate() error {
	// Check if DB is initialized
	DB := GetDB()
	if DB == nil {
		return errors.New("database not initialized")
	}

	// Perform migrations
	err := DB.AutoMigrate(
		&models.Area{},
		&models.Contact{},
		&models.Constituency{},
		&models.County{},
		&models.Region{},
		&models.UssdSession{},
	// Add other models as needed
	)

	if err != nil {
		return err
	}

	return nil
}
