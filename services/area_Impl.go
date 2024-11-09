package services

import (
	"fmt"
	"notification-app/db"
	"notification-app/models"
)

func GetAllAreas(Area *[]models.Area) (err error) {
	if err = db.GetDB().Find(Area).Error; err != nil {
		return err
	}
	return nil
}

// Create Area
func CreateArea(Area *models.Area) (err error) {
	if err = db.GetDB().Create(Area).Error; err != nil {
		return err
	}
	return nil
}

// Get Area ByID
func GetAreaByID(Area *models.Area, id string) (err error) {
	if err = db.GetDB().Where("area_id = ?", id).First(Area).Error; err != nil {
		return err
	}
	return nil
}

func GetAreaContactsByID(Area *models.Area, id string) (err error) {
	if err = db.GetDB().Preload("Contacts").Where("area_id = ?", id).First(Area).Error; err != nil {
		return err
	}
	return nil
}

// Update Area
func UpdateArea(Area *models.Area, id string) (err error) {
	fmt.Println(Area)
	db.GetDB().Save(Area)
	return nil
}

// Delete Area
func DeleteArea(Area *models.Area, id string) (err error) {
	db.GetDB().Where("area_id = ?", id).Delete(Area)
	return nil
}
