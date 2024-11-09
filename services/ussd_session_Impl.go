package services

import (
	"notification-app/db"
	"notification-app/models"
)

// GetAllUssdSessions retrieves all UssdSession records
func GetAllUssdSessions(sessions *[]models.UssdSession) error {
	if err := db.GetDB().Find(sessions).Error; err != nil {
		return err
	}
	return nil
}

// CreateUssdSession creates a new UssdSession record
func CreateUssdSession(session *models.UssdSession) error {
	if err := db.GetDB().Create(session).Error; err != nil {
		return err
	}
	return nil
}

// GetUssdSessionByID retrieves a UssdSession by its ID
func GetUssdSessionByID(session *models.UssdSession, id string) error {
	if err := db.GetDB().Where("session_id = ?", id).First(session).Error; err != nil {
		return err
	}
	return nil
}

// GetUssdSessionByMsisdn retrieves a UssdSession by Msisdn
func GetUssdSessionByMsisdn(session *models.UssdSession, msisdn int64) error {
	if err := db.GetDB().Where("msisdn = ?", msisdn).First(session).Error; err != nil {
		return err
	}
	return nil
}

// UpdateUssdSession updates an existing UssdSession
func UpdateUssdSession(updates map[string]interface{}, id string) error {
	result := db.GetDB().Model(&models.UssdSession{}).
		Where("session_id = ?", id).
		Updates(updates)
	if result.Error != nil {
		return result.Error
	}
	return nil
}

// DeleteUssdSession deletes a UssdSession by its ID
func DeleteUssdSession(id string) error {
	return db.GetDB().Where("session_id = ?", id).Delete(&models.UssdSession{}).Error
}

// GetIncompleteUssdSessions retrieves all incomplete UssdSession records
func GetIncompleteUssdSessions(sessions *[]models.UssdSession) error {
	if err := db.GetDB().Where("completed = ?", "No").Find(sessions).Error; err != nil {
		return err
	}
	return nil
}
