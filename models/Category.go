package models

import "time"

type Category struct {
	CatID       uint      `gorm:"column:cat_id;primaryKey;autoIncrement"`
	ParentID    int64     `gorm:"column:parent_id;not null"`
	Name        string    `gorm:"column:name;not null"`
	Description string    `gorm:"column:description;not null"`
	Amount      int64     `gorm:"column:amount;not null"`
	DateCreated time.Time `json:"-" , gorm:"column:date_created;autoCreateTime"`
	LastUpdate  time.Time `json:"-" , gorm:"column:last_update;autoUpdateTime"`
	Contacts    []Contact `gorm:"foreignKey:CatID"`
	Mapping     []Mapping `gorm:"foreignKey:ParentID"`
}

func (Category) TableName() string {
	return "tbl_category"
}
