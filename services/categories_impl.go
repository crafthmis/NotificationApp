package services

import (
	"fmt"
	"notification-app/db"
	"notification-app/models"
)

func GetAllCategories(Category *[]models.Category) (err error) {
	if err = db.GetDB().Find(Category).Error; err != nil {
		return err
	}
	return nil
}

// Create Category
func CreateCategory(Category *models.Category) (err error) {
	if err = db.GetDB().Create(Category).Error; err != nil {
		return err
	}
	return nil
}

// Get Category ByID
func GetCategoryByID(Category *models.Category, id string) (err error) {
	if err = db.GetDB().Where("cat_id = ?", id).First(Category).Error; err != nil {
		return err
	}
	return nil
}
func GetCategoriesyByID(Category *[]models.Category, id string) (err error) {
	if err = db.GetDB().Model(Category).Joins("INNER JOIN tbl_category_mapping ON tbl_category.cat_id = tbl_category_mapping.cat_id").Select("tbl_category.cat_id", "name").Where("tbl_category_mapping.parent_id in (?)", id).Order("tbl_category.cat_id asc").Find(Category).Error; err != nil {
		return err
	}
	return nil
}

func GetCategoryContactsByID(Category *models.Category, id string) (err error) {
	if err = db.GetDB().Preload("Contacts").Where("cat_id = ?", id).First(Category).Error; err != nil {
		return err
	}
	return nil
}

// Update Category
func UpdateCategory(Category *models.Category, id string) (err error) {
	fmt.Println(Category)
	db.GetDB().Save(Category)
	return nil
}

// Delete Category
func DeleteCategory(Category *models.Category, id string) (err error) {
	db.GetDB().Where("cat_id = ?", id).Delete(Category)
	return nil
}
