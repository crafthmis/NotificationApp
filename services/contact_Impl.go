package services

import (
	"fmt"
	"notification-app/db"
	"notification-app/models"
)

func GetAllContacts(Contact *[]models.Contact) (err error) {
	if err = db.GetDB().Find(Contact).Error; err != nil {
		return err
	}
	return nil
}

// Create Contact
func CreateContact(Contact *models.Contact) (err error) {
	if err = db.GetDB().Create(Contact).Error; err != nil {
		return err
	}
	return nil
}

// Get Contact ByID
func GetContactByID(Contact *models.Contact, id string) (err error) {
	if err = db.GetDB().Where("cnt_id = ?", id).First(Contact).Error; err != nil {
		return err
	}
	return nil
}

// Update Contact
func UpdateContact(Contact *models.Contact, id string) (err error) {
	fmt.Println(Contact)
	db.GetDB().Save(Contact)
	return nil
}

// Delete Contact
func DeleteContact(Contact *models.Contact, id string) (err error) {
	db.GetDB().Where("cnt_id = ?", id).Delete(Contact)
	return nil
}
