package models

import (
	"time"
)

// County represents the county entity
type County struct {
	CtyID          uint `gorm:"primaryKey;column:cty_id;autoIncrement"`
	RegID          uint `json:"-",gorm:"column:reg_id"`
	Code           string
	Name           string
	Region         *Region        `gorm:"foreignKey:RegID"`
	Constituencies []Constituency `gorm:"foreignKey:CtyID;association_foreignkey:CtyID"`
	DateCreated    time.Time      `json:"-",gorm:"column:date_created;autoCreateTime"`
	LastUpdate     time.Time      `json:"-",gorm:"column:last_update;autoUpdateTime"`
}

// TableName specifies the table name for the County model
func (County) TableName() string {
	return "tbl_county"
}
