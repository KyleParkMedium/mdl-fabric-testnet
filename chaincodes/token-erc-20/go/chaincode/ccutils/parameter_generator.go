package ccutils

import (
	"time"
)

func CreateKstTime() string {
	nowDate := time.Now()
	targetUtcTime := nowDate.UTC()
	kstTime := targetUtcTime.In(time.FixedZone("KST", 9*60*60))
	kstString := kstTime.Format("2006-01-02")
	return kstString
}

func CreateKstTimeAddDate(years int, months int, days int) string {
	nowDate := time.Now().AddDate(years, months, days)
	targetUtcTime := nowDate.UTC()
	kstTime := targetUtcTime.In(time.FixedZone("KST", 9*60*60))
	kstString := kstTime.Format("2006-01-02")
	return kstString
}

func CreateKstTimeAndSecond() string {
	nowDate := time.Now()
	targetUtcTime := nowDate.UTC()
	kstTime := targetUtcTime.In(time.FixedZone("KST", 9*60*60))
	kstString := kstTime.Format("2006-01-02 15:04:05")
	return kstString
}

func CreateKstYear() string {
	nowDate := time.Now()
	targetUtcTime := nowDate.UTC()
	kstTime := targetUtcTime.In(time.FixedZone("KST", 9*60*60))
	kstYearString := kstTime.Format("2006")

	return kstYearString
}

func CreateKstMonth() string {
	nowDate := time.Now()
	targetUtcTime := nowDate.UTC()
	kstTime := targetUtcTime.In(time.FixedZone("KST", 9*60*60))
	kstMonthString := kstTime.Format("01")

	return kstMonthString
}

func CreateKstDay() string {
	nowDate := time.Now()
	targetUtcTime := nowDate.UTC()
	kstTime := targetUtcTime.In(time.FixedZone("KST", 9*60*60))
	kstDayString := kstTime.Format("02")

	return kstDayString
}

func CreateTimeUnix() int64 {
	return time.Now().Unix()
}

func CreateTimeUnixNano() int64 {
	return time.Now().Unix()
}

func ClearNullParams(params map[string]interface{}) {
	for key, value := range params {
		if value == nil {
			delete(params, key)
		}
	}
}
