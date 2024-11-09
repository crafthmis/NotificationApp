package controllers

import (
	"fmt"
	"notification-app/models"
	"notification-app/services"
	"net/http"

	"github.com/gin-gonic/gin"
)

// Get Countys
func GetCounties(c *gin.Context) {
	var County []models.County

	err := services.GetAllCounty(&County)
	if err != nil {
		c.AbortWithStatus(http.StatusNotFound)
	} else {
		c.JSON(http.StatusOK, County)
	}
}

// Get County
func GetCounty(c *gin.Context) {
	var County models.County
	id := c.Params.ByName("id")

	err := services.GetCountyByID(&County, id)
	if err != nil {
		c.AbortWithStatus(http.StatusNotFound)
	} else {
		c.JSON(http.StatusOK, County)
	}
}

// Create County
func CreateCounty(c *gin.Context) {
	var County models.County
	c.ShouldBindJSON(&County)

	err := services.CreateCounty(&County)
	if err != nil {
		fmt.Println(err.Error())
		c.AbortWithStatus(http.StatusNotFound)
	} else {
		c.JSON(http.StatusOK, County)
	}
}

// Update County
func UpdateCounty(c *gin.Context) {
	var County models.County
	id := c.Params.ByName("id")

	err := services.GetCountyByID(&County, id)
	if err != nil {
		c.JSON(http.StatusNotFound, County)
	}

	c.ShouldBindJSON(&County)

	err = services.UpdateCounty(&County, id)
	if err != nil {
		c.AbortWithStatus(http.StatusNotFound)
	} else {
		c.JSON(http.StatusOK, County)
	}
}

// Delete County
func DeleteCounty(c *gin.Context) {
	var County models.County
	id := c.Params.ByName("id")

	err := services.DeleteCounty(&County, id)
	if err != nil {
		c.AbortWithStatus(http.StatusNotFound)
	} else {
		c.JSON(http.StatusOK, gin.H{"id" + id: "is deleted"})
	}
}
