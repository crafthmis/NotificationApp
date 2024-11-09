package services

import (
	"fmt"
	"notification-app/db"
	"notification-app/models"
)

func GetAllRegion(Region *[]models.Region) (err error) {
	if err = db.GetDB().Find(Region).Error; err != nil {
		return err
	}
	return nil
}

// Create Region
func CreateRegion(Region *models.Region) (err error) {
	if err = db.GetDB().Create(Region).Error; err != nil {
		return err
	}
	return nil
}

// Get Region ByID
func GetRegionByID(Region *models.Region, id string) (err error) {
	if err = db.GetDB().Preload("Counties").Where("reg_id = ?", id).First(Region).Error; err != nil {
		return err
	}
	return nil
}

// Update Region
func UpdateRegion(Region *models.Region, id string) (err error) {
	fmt.Println(Region)
	db.GetDB().Save(Region)
	return nil
}

// Delete Region
func DeleteRegion(Region *models.Region, id string) (err error) {
	db.GetDB().Where("reg_id = ?", id).Delete(Region)
	return nil
}
