package controllers

import (
	"net/http"

	"notification-app/sms"

	at "github.com/edwinwalela/africastalking-go/pkg/sms"
	"github.com/gin-gonic/gin"
)

func SendBulkSMS(c *gin.Context) {
	var bulkRequest at.BulkRequest

	if err := c.ShouldBindJSON(&bulkRequest); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	response, err := sms.SendBulk(&bulkRequest)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, response)
}
