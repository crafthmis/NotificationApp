package controllers

import (
	"fmt"
	"net/http"
	"notification-app/models"
	"notification-app/services"

	"github.com/gin-gonic/gin"
)

// Get Areas
func GetAreas(c *gin.Context) {
	var Area []models.Area

	err := services.GetAllAreas(&Area)
	if err != nil {
		c.AbortWithStatus(http.StatusNotFound)
	} else {
		c.JSON(http.StatusOK, Area)
	}
}

// Get Area
func GetArea(c *gin.Context) {
	var Area models.Area
	id := c.Params.ByName("id")

	err := services.GetAreaByID(&Area, id)
	if err != nil {
		c.AbortWithStatus(http.StatusNotFound)
	} else {
		c.JSON(http.StatusOK, Area)
	}
}

func GetAreaContacts(c *gin.Context) {
	var Area models.Area

	id := c.Params.ByName("id")

	err := services.GetAreaContactsByID(&Area, id)
	if err != nil {
		c.AbortWithStatus(http.StatusNotFound)
	} else {
		c.JSON(http.StatusOK, Area.Contacts)
	}
}

// Create Area
func CreateArea(c *gin.Context) {
	var Area models.Area
	c.ShouldBindJSON(&Area)

	err := services.CreateArea(&Area)
	if err != nil {
		fmt.Println(err.Error())
		c.AbortWithStatus(http.StatusNotFound)
	} else {
		c.JSON(http.StatusOK, Area)
	}
}

// Update Area
func UpdateArea(c *gin.Context) {
	var Area models.Area
	id := c.Params.ByName("id")

	err := services.GetAreaByID(&Area, id)
	if err != nil {
		c.JSON(http.StatusNotFound, Area)
	}

	c.ShouldBindJSON(&Area)

	err = services.UpdateArea(&Area, id)
	if err != nil {
		c.AbortWithStatus(http.StatusNotFound)
	} else {
		c.JSON(http.StatusOK, Area)
	}
}

// Delete Area
func DeleteArea(c *gin.Context) {
	var Area models.Area
	id := c.Params.ByName("id")

	err := services.DeleteArea(&Area, id)
	if err != nil {
		c.AbortWithStatus(http.StatusNotFound)
	} else {
		c.JSON(http.StatusOK, gin.H{"id" + id: "is deleted"})
	}
}
