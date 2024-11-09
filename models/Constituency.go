package models

import (
	"time"

	_ "gorm.io/gorm"
)

// Constituency represents the constituency entity
type Constituency struct {
	CstID       uint `gorm:"primaryKey;column:cst_id;autoIncrement"`
	CtyID       uint `json:"-",gorm:"column:cty_id"`
	Name        string
	Areas       []Area    `gorm:"foreignKey:CstID;association_foreignkey:CstID"`
	County      *County   `gorm:"foreignKey:CtyID"`
	DateCreated time.Time `json:"-",gorm:"column:date_created;autoCreateTime"`
	LastUpdate  time.Time `json:"-",gorm:"column:last_update;autoUpdateTime"`
}

// TableName specifies the table name for the Constituency model
func (Constituency) TableName() string {
	return "tbl_constituency"
}
