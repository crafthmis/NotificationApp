package controllers

import (
	"fmt"
	"net/http"
	"notification-app/models"
	"notification-app/services"

	"github.com/gin-gonic/gin"
)

// Get Categorys
func GetCategories(c *gin.Context) {
	var Category []models.Category

	err := services.GetAllCategories(&Category)
	if err != nil {
		c.AbortWithStatus(http.StatusNotFound)
	} else {
		c.JSON(http.StatusOK, Category)
	}
}

// Get Category
func GetCategory(c *gin.Context) {
	var Category models.Category
	id := c.Params.ByName("id")

	err := services.GetCategoryByID(&Category, id)
	if err != nil {
		c.AbortWithStatus(http.StatusNotFound)
	} else {
		c.JSON(http.StatusOK, Category)
	}
}

// Create Category
func CreateCategory(c *gin.Context) {
	var Category models.Category
	c.ShouldBindJSON(&Category)

	err := services.CreateCategory(&Category)
	if err != nil {
		fmt.Println(err.Error())
		c.AbortWithStatus(http.StatusNotFound)
	} else {
		c.JSON(http.StatusOK, Category)
	}
}

// Update Category
func UpdateCategory(c *gin.Context) {
	var Category models.Category
	id := c.Params.ByName("id")

	err := services.GetCategoryByID(&Category, id)
	if err != nil {
		c.JSON(http.StatusNotFound, Category)
	}

	c.ShouldBindJSON(&Category)

	err = services.UpdateCategory(&Category, id)
	if err != nil {
		c.AbortWithStatus(http.StatusNotFound)
	} else {
		c.JSON(http.StatusOK, Category)
	}
}

// Delete Category
func DeleteCategory(c *gin.Context) {
	var Category models.Category
	id := c.Params.ByName("id")

	err := services.DeleteCategory(&Category, id)
	if err != nil {
		c.AbortWithStatus(http.StatusNotFound)
	} else {
		c.JSON(http.StatusOK, gin.H{"id" + id: "is deleted"})
	}
}
