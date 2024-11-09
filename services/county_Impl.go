package services

import (
	"fmt"
	"notification-app/db"
	"notification-app/models"
)

func GetAllCounty(County *[]models.County) (err error) {
	if err = db.GetDB().Find(County).Error; err != nil {
		return err
	}
	return nil
}

// Create County
func CreateCounty(County *models.County) (err error) {
	if err = db.GetDB().Create(County).Error; err != nil {
		return err
	}
	return nil
}

// Get County ByID
func GetCountyByID(County *models.County, id string) (err error) {
	if err = db.GetDB().Preload("Constituencies").Where("cty_id = ?", id).First(County).Error; err != nil {
		return err
	}
	return nil
}

// Update County
func UpdateCounty(County *models.County, id string) (err error) {
	fmt.Println(County)
	db.GetDB().Save(County)
	return nil
}

// Delete County
func DeleteCounty(County *models.County, id string) (err error) {
	db.GetDB().Where("cty_id = ?", id).Delete(County)
	return nil
}
