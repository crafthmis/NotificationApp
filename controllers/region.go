package controllers

import (
	"fmt"
	"net/http"
	"notification-app/models"
	"notification-app/services"

	"github.com/gin-gonic/gin"
)

// Get Regions
func GetRegions(c *gin.Context) {
	var Region []models.Region

	err := services.GetAllRegion(&Region)
	if err != nil {
		c.AbortWithStatus(http.StatusNotFound)
	} else {
		c.JSON(http.StatusOK, Region)
	}
}

// Get Region
func GetRegion(c *gin.Context) {
	var Region models.Region
	id := c.Params.ByName("id")

	err := services.GetRegionByID(&Region, id)
	if err != nil {
		c.AbortWithStatus(http.StatusNotFound)
	} else {
		c.JSON(http.StatusOK, Region)
	}
}

// Create Region
func CreateRegion(c *gin.Context) {
	var Region models.Region
	c.ShouldBindJSON(&Region)

	err := services.CreateRegion(&Region)
	if err != nil {
		fmt.Println(err.Error())
		c.AbortWithStatus(http.StatusNotFound)
	} else {
		c.JSON(http.StatusOK, Region)
	}
}

// Update Region
func UpdateRegion(c *gin.Context) {
	var Region models.Region
	id := c.Params.ByName("id")

	err := services.GetRegionByID(&Region, id)
	if err != nil {
		c.JSON(http.StatusNotFound, Region)
	}

	c.ShouldBindJSON(&Region)

	err = services.UpdateRegion(&Region, id)
	if err != nil {
		c.AbortWithStatus(http.StatusNotFound)
	} else {
		c.JSON(http.StatusOK, Region)
	}
}

// Delete Region
func DeleteRegion(c *gin.Context) {
	var Region models.Region
	id := c.Params.ByName("id")

	err := services.DeleteRegion(&Region, id)
	if err != nil {
		c.AbortWithStatus(http.StatusNotFound)
	} else {
		c.JSON(http.StatusOK, gin.H{"id" + id: "is deleted"})
	}
}
