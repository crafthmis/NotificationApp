package db

import (
	"fmt"
	"os"
	"strconv"
	"time"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/schema"
)

type DBConfig struct {
	Host     string
	Port     int
	User     string
	DBName   string
	Password string
	SSLMode  string
}

var DB *gorm.DB

func BuildDBConfig() *DBConfig {
	dbConfig := DBConfig{
		Host:     os.Getenv("POSTGRES_HOST"),
		Port:     portConv(os.Getenv("POSTGRES_PORT")),
		User:     os.Getenv("POSTGRES_USER"),
		Password: os.Getenv("POSTGRES_PASSWORD"),
		DBName:   os.Getenv("POSTGRES_DB"),
		SSLMode:  os.Getenv("POSTGRES_SSL_MODE"),
	}
	return &dbConfig
}

// convert string to int
func portConv(s string) int {
	i, err := strconv.Atoi(s)
	if err != nil {
		panic(err)
	}
	return i
}

func DbURL(dbConfig *DBConfig) string {
	return fmt.Sprintf(
		"user=%s password=%s host=%s port=%d dbname=%s sslmode=%s",
		dbConfig.User,
		dbConfig.Password,
		dbConfig.Host,
		dbConfig.Port,
		dbConfig.DBName,
		dbConfig.SSLMode,
	)
}

func DatabaseInit() error {
	dbConfig := BuildDBConfig()
	dbURL := DbURL(dbConfig)

	var err error
	//DB, err = gorm.Open(postgres.Open(dbURL), &gorm.Config{})
	DB, err = gorm.Open(postgres.Open(dbURL), &gorm.Config{
		DisableForeignKeyConstraintWhenMigrating: true,
		NamingStrategy: schema.NamingStrategy{
			TablePrefix:   "kplc_schema.", // schema name
			SingularTable: false,
		}})
	if err != nil {
		panic("Failed to connect to database")
	}
	sqlDB, err2 := DB.DB()

	if err2 != nil {
		return err2
	}

	// Set max number of open connections
	sqlDB.SetMaxOpenConns(100)

	// Set max number of idle connections
	sqlDB.SetMaxIdleConns(10)

	// Set max lifetime of a connection
	sqlDB.SetConnMaxLifetime(time.Hour)

	return nil
}

func GetDB() *gorm.DB {
	DatabaseInit()
	return DB
}
