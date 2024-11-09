package controllers

import (
	"fmt"
	"net/http"
	"notification-app/models"
	"notification-app/services"

	"github.com/gin-gonic/gin"
)

// Get Constituencys
func GetConstituencies(c *gin.Context) {
	var Constituency []models.Constituency

	err := services.GetAllConstituency(&Constituency)
	if err != nil {
		c.AbortWithStatus(http.StatusNotFound)
	} else {
		c.JSON(http.StatusOK, Constituency)
	}
}

// Get Constituency
func GetConstituency(c *gin.Context) {
	var Constituency models.Constituency
	id := c.Params.ByName("id")

	err := services.GetConstituencyByID(&Constituency, id)
	if err != nil {
		c.AbortWithStatus(http.StatusNotFound)
	} else {
		c.JSON(http.StatusOK, Constituency)
	}
}

// Create Constituency
func CreateConstituency(c *gin.Context) {
	var Constituency models.Constituency
	c.BindJSON(&Constituency)

	err := services.CreateConstituency(&Constituency)
	if err != nil {
		fmt.Println(err.Error())
		c.AbortWithStatus(http.StatusNotFound)
	} else {
		c.JSON(http.StatusOK, Constituency)
	}
}

// Update Constituency
func UpdateConstituency(c *gin.Context) {
	var Constituency models.Constituency
	id := c.Params.ByName("id")

	err := services.GetConstituencyByID(&Constituency, id)
	if err != nil {
		c.JSON(http.StatusNotFound, Constituency)
	}

	c.BindJSON(&Constituency)

	err = services.UpdateConstituency(&Constituency, id)
	if err != nil {
		c.AbortWithStatus(http.StatusNotFound)
	} else {
		c.JSON(http.StatusOK, Constituency)
	}
}

// Delete Constituency
func DeleteConstituency(c *gin.Context) {
	var Constituency models.Constituency
	id := c.Params.ByName("id")

	err := services.DeleteConstituency(&Constituency, id)
	if err != nil {
		c.AbortWithStatus(http.StatusNotFound)
	} else {
		c.JSON(http.StatusOK, gin.H{"id" + id: "is deleted"})
	}
}
