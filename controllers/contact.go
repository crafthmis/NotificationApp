package controllers

import (
	"fmt"
	"net/http"
	"notification-app/models"
	"notification-app/services"

	"github.com/gin-gonic/gin"
)

// Get Contacts
func GetContacts(c *gin.Context) {
	var Contact []models.Contact

	err := services.GetAllContacts(&Contact)
	if err != nil {
		c.AbortWithStatus(http.StatusNotFound)
	} else {
		c.JSON(http.StatusOK, Contact)
	}
}

// Get Contact
func GetContact(c *gin.Context) {
	var Contact models.Contact
	id := c.Params.ByName("id")

	err := services.GetContactByID(&Contact, id)
	if err != nil {
		c.AbortWithStatus(http.StatusNotFound)
	} else {
		c.JSON(http.StatusOK, Contact)
	}
}

// Create Contact
func CreateContact(c *gin.Context) {
	var Contact models.Contact

	c.ShouldBindJSON(&Contact)

	var errHash error
	//Contact.Password, errHash = utils.GenerateHashPassword(Contact.Password)

	if errHash != nil {
		c.JSON(500, gin.H{"error": "could not generate password hash"})
		return
	}

	err := services.CreateContact(&Contact)

	if err != nil {
		fmt.Println(err.Error())
		c.JSON(http.StatusConflict, gin.H{"error": "an error has occured"})
	} else {
		c.JSON(http.StatusOK, Contact)
	}
}

// Update Contact
func UpdateContact(c *gin.Context) {
	var Contact models.Contact
	id := c.Params.ByName("id")

	err := services.GetContactByID(&Contact, id)
	if err != nil {
		c.JSON(http.StatusNotFound, Contact)
	}

	err = services.UpdateContact(&Contact, id)
	if err != nil {
		c.AbortWithStatus(http.StatusNotFound)
	} else {
		c.JSON(http.StatusOK, Contact)
	}
}

// Delete Contact
func DeleteContact(c *gin.Context) {
	var Contact models.Contact
	id := c.Params.ByName("id")

	err := services.DeleteContact(&Contact, id)
	if err != nil {
		c.AbortWithStatus(http.StatusNotFound)
	} else {
		c.JSON(http.StatusOK, gin.H{"id" + id: "is deleted"})
	}
}
