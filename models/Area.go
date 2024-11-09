package models

import (
	"time"
)

type Area struct {
	AreaID       uint `gorm:"primaryKey;column:area_id;autoIncrement"`
	CstID        uint `json:"-",gorm:"column:cst_id"`
	Name         string
	Lon          string `gorm:"column:long"`
	Lat          string
	Constituency *Constituency `gorm:"foreignKey:CstID"`
	Contacts     []Contact     `gorm:"foreignKey:AreaID;association_foreignkey:AreaID"`
	DateCreated  time.Time     `json:"-",gorm:"column:date_created;autoCreateTime"`
	LastUpdate   time.Time     `json:"-",gorm:"column:last_update;autoUpdateTime"`
}

func (Area) TableName() string {
	return "tbl_area"
}
