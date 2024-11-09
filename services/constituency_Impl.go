package services

import (
	"fmt"
	"notification-app/db"
	"notification-app/models"
)

func GetAllConstituency(Constituency *[]models.Constituency) (err error) {
	if err = db.GetDB().Find(Constituency).Error; err != nil {
		return err
	}
	return nil
}

// Create Constituency
func CreateConstituency(Constituency *models.Constituency) (err error) {
	if err = db.GetDB().Create(Constituency).Error; err != nil {
		return err
	}
	return nil
}

// Get Constituency ByID
func GetConstituencyByID(Constituency *models.Constituency, id string) (err error) {
	if err = db.GetDB().Preload("Areas").Where("cst_id = ?", id).First(Constituency).Error; err != nil {
		return err
	}
	return nil
}

// Update Constituency
func UpdateConstituency(Constituency *models.Constituency, id string) (err error) {
	fmt.Println(Constituency)
	db.GetDB().Save(Constituency)
	return nil
}

// Delete Constituency
func DeleteConstituency(Constituency *models.Constituency, id string) (err error) {
	db.GetDB().Where("cst_id = ?", id).Delete(Constituency)
	return nil
}
