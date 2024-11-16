package models

import "time"

type Mapping struct {
	CtmID       uint      `gorm:"column:ctm_id;primaryKey;autoIncrement"`
	CatID       int64     `gorm:"column:cat_id;not null"`
	ParentID    int64     `gorm:"column:parent_id;not null"`
	DateCreated time.Time `json:"-" , gorm:"column:date_created;autoCreateTime"`
	LastUpdate  time.Time `json:"-" , gorm:"column:last_update;autoUpdateTime"`
	Category    *Category `gorm:"belongsTo:Category;foreignKey:ParentID"`
}

func (Mapping) TableName() string {
	return "tbl_category_mapping"
}
