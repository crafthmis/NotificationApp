package models

import (
	"time"
)

// Region represents the region entity
type Region struct {
	RegID       uint `gorm:"primaryKey;column:reg_id;autoIncrement"`
	Name        string
	Counties    []County  `gorm:"foreignKey:RegID;association_foreignkey:RegID"`
	DateCreated time.Time `json:"-" , gorm:"column:date_created;autoCreateTime"`
	LastUpdate  time.Time `json:"-" , gorm:"column:last_update;autoUpdateTime"`
}

// TableName specifies the table name for the Region model
func (Region) TableName() string {
	return "tbl_region"
}
