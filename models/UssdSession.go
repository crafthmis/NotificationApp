package models

import "time"

type UssdSession struct {
	SessionID           string    `json:"session_id" db:"session_id" gorm:"primaryKey;column:session_id;table:tbl_ussd_sesions"`
	Msisdn              string    `json:"msisdn" db:"msisdn" gorm:"column:msisdn;not null"`
	PlanPayload         string    `json:"plan_payload" db:"plan_payload" gorm:"column:plan_payload"`
	RegionPayload       string    `json:"region_payload" db:"region_payload" gorm:"column:region_payload"`
	CountyPayload       string    `json:"county_payload" db:"county_payload" gorm:"column:county_payload"`
	ConstituencyPayload string    `json:"constituency_payload" db:"constituency_payload" gorm:"column:constituency_payload"`
	AreaPayload         string    `json:"area_payload" db:"area_payload" gorm:"column:area_payload"`
	Completed           string    `json:"completed" db:"completed" gorm:"column:completed;default:No"`
	DateCreated         time.Time `json:"date_created" db:"date_created" gorm:"column:date_created;default:current_timestamp"`
	LastUpdate          time.Time `json:"last_update" db:"last_update" gorm:"column:last_update;not null"`
}

func (UssdSession) TableName() string {
	return "tbl_ussd_sesions"
}
