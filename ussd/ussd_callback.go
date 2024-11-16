package ussd

import (
	"encoding/json"
	"fmt"
	"net/http"
	"notification-app/models"
	"notification-app/services"
	"strconv"
	"strings"
)

var lastIndexOf int
var firstIndexOf int
var firstIndexAfterAstk int

func UssdCallback(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("content-type", "text/plain")
	// recieve formValue from AT
	session_id := r.FormValue("sessionId")
	service_code := r.FormValue("serviceCode")
	phone_number := r.FormValue("phoneNumber")
	text := r.FormValue("text")

	fmt.Printf("%s,%s,%s", session_id, service_code, phone_number)

	fmt.Printf("\n Text %s", text)

	// if the text field is empty, this indicates that this is the begining of a session
	if len(text) == 0 {
		// form the response to be sent back to the user
		var Categories []models.Category

		//err := services.GetCategoriesyByID(&Categories, fmt.Sprintf("%d", 0))
		err := services.GetCategoriesyByID(&Categories, fmt.Sprintf("%d", 0))
		if err != nil {
			w.Write([]byte("END System is currently busy. Kindly try again"))
			return
		}
		var accumulator []string

		for _, sub := range Categories {
			result := fmt.Sprintf("\n%d. %s", sub.CatID, sub.Name)
			accumulator = append(accumulator, result)
		}
		err = services.CreateUssdSession(&models.UssdSession{SessionID: session_id, Msisdn: phone_number})
		if err != nil {
			fmt.Println(err.Error())
			w.Write([]byte("END System is currently busy. Kindly try again"))
			return
		}
		jsonData, err := json.MarshalIndent(Categories, "", "  ")
		if err != nil {
			fmt.Println("Error marshalling to JSON:", err)
			w.Write([]byte("END System is currently busy. Kindly try again"))
			return
		}
		updates := map[string]interface{}{
			"plan_payload": string(jsonData),
		}
		err = services.UpdateUssdSession(updates, session_id)
		if err != nil {
			fmt.Println(err.Error())
			w.Write([]byte("END System is currently busy. Kindly try again"))
			return
		}
		output := strings.Join(accumulator, "")
		fmt.Println(output)
		w.Write([]byte(fmt.Sprintf("CON Welcome to Nipashe. Kindly register for. %s", output)))
		return
	} else {
		//   On user input the switch block is executed, remember our text field is concatenated on every user input
		cnt := strings.Count(text, "*")
		fmt.Printf("\nHow many astericks %d", cnt)
		lastIndexOf = getLastValueAfterAsterisk(text)
		firstIndexOf = getfirstValueBeforeAsterisk(text)
		firstIndexAfterAstk = getXValueAfterAsterisk(text)

		if text == "1" || firstIndexOf == 1 {
			if cnt == 0 {
				var Categories []models.Category
				fmt.Printf("\nLast Index of  %d", lastIndexOf)
				err := services.GetCategoriesyByID(&Categories, text)
				if err != nil {
					w.Write([]byte("END System is currently busy. Kindly try again"))
					return
				}
				var accumulator []string

				for idx, sub := range Categories {
					result := fmt.Sprintf("\n%d. %s", idx+1, sub.Name)
					accumulator = append(accumulator, result)
				}
				if err != nil {
					fmt.Println(err.Error())
					w.Write([]byte("END System is currently busy. Kindly try again"))
					return
				}
				jsonData, err := json.MarshalIndent(Categories, "", "  ")
				if err != nil {
					fmt.Println("Error marshalling to JSON:", err)
					w.Write([]byte("END System is currently busy. Kindly try again"))
					return
				}
				updates := map[string]interface{}{
					"plan_payload": string(jsonData),
				}
				err = services.UpdateUssdSession(updates, session_id)
				if err != nil {
					fmt.Println(err.Error())
					w.Write([]byte("END System is currently busy. Kindly try again"))
					return
				}
				output := strings.Join(accumulator, "")
				//fmt.Println(output)
				w.Write([]byte(fmt.Sprintf("CON Choose your alert service. %s", output)))
			} else if cnt == 1 && (firstIndexAfterAstk == 1 || firstIndexAfterAstk == 2) {
				var session models.UssdSession
				err := services.GetUssdSessionByID(&session, session_id)
				if err != nil {
					w.Write([]byte("END System is currently busy. Kindly try again"))
					return
				}

				var categories []models.Category
				err = json.Unmarshal([]byte(session.PlanPayload), &categories)
				if err != nil {
					w.Write([]byte("END System is currently busy. Kindly try again"))
					fmt.Println("Error unmarshalling JSON:", err)
					return
				}

				catg, err := GetSubCategoriesByIndex(categories, lastIndexOf-1)

				fmt.Printf("\nCategory Name %s", catg.Name)

				if err != nil {
					w.Write([]byte("END System is currently busy. Kindly try again"))
					return
				}
				var catgs []models.Category
				err = services.GetCategoriesyByID(&catgs, fmt.Sprintf("%d", catg.CatID))
				if err != nil {
					w.Write([]byte("END System is currently busy. Kindly try again"))
					return
				}
				var accumulator []string
				for idx, category := range catgs {
					result := fmt.Sprintf("\n%d. %s", idx+1, category.Name)
					accumulator = append(accumulator, result)
				}
				// Save categories
				jsonData, err := json.MarshalIndent(catgs, "", "  ")
				if err != nil {
					fmt.Println("Error marshalling to JSON:", err)
					w.Write([]byte("END System is currently busy. Kindly try again"))
					return
				}
				updates := map[string]interface{}{
					"plan_payload": string(jsonData),
				}
				err = services.UpdateUssdSession(updates, session_id)
				if err != nil {
					fmt.Println(err.Error())
					w.Write([]byte("END System is currently busy. Kindly try again"))
					return
				}

				output := strings.Join(accumulator, "")
				fmt.Println(output)
				w.Write([]byte(fmt.Sprintf("CON Choose your preffered Broad category. %s", output)))
				return
			} else if cnt == 2 && (firstIndexAfterAstk == 1 || firstIndexAfterAstk == 2) {
				var session models.UssdSession
				err := services.GetUssdSessionByID(&session, session_id)
				if err != nil {
					w.Write([]byte("END System is currently busy. Kindly try again"))
					return
				}

				var categories []models.Category
				err = json.Unmarshal([]byte(session.PlanPayload), &categories)
				if err != nil {
					w.Write([]byte("END System is currently busy. Kindly try again"))
					fmt.Println("Error unmarshalling JSON:", err)
					return
				}

				catg, err := GetSubCategoriesByIndex(categories, lastIndexOf-1)

				fmt.Printf("\nCategory Name %s", catg.Name)

				if err != nil {
					w.Write([]byte("END System is currently busy. Kindly try again"))
					return
				}
				var catgs []models.Category
				err = services.GetCategoriesyByID(&catgs, fmt.Sprintf("%d", catg.CatID))
				if err != nil {
					w.Write([]byte("END System is currently busy. Kindly try again"))
					return
				}
				var accumulator []string
				for idx, category := range catgs {
					result := fmt.Sprintf("\n%d. %s", idx+1, category.Name)
					accumulator = append(accumulator, result)
				}
				// Save categories
				jsonData, err := json.MarshalIndent(catgs, "", "  ")
				if err != nil {
					fmt.Println("Error marshalling to JSON:", err)
					w.Write([]byte("END System is currently busy. Kindly try again"))
					return
				}
				updates := map[string]interface{}{
					"plan_payload": string(jsonData),
				}
				err = services.UpdateUssdSession(updates, session_id)
				if err != nil {
					fmt.Println(err.Error())
					w.Write([]byte("END System is currently busy. Kindly try again"))
					return
				}
				result := fmt.Sprintf("\n%d. %s", 7, "Add Job Category")
				accumulator = append(accumulator, result)
				output := strings.Join(accumulator, "")
				fmt.Println(output)
				w.Write([]byte(fmt.Sprintf("CON Choose your preffered job category. %s", output)))
				return

			} else if cnt == 3 && (firstIndexAfterAstk == 1 || firstIndexAfterAstk == 2) && lastIndexOf == 7 {
				w.Write([]byte("CON Enter category. "))
			} else if cnt == 3 && (firstIndexAfterAstk == 1 || firstIndexAfterAstk == 2) && lastIndexOf != 7 {

				var regions []models.Region
				err := services.GetAllRegion(&regions)
				if err != nil {
					w.Write([]byte("END System is currently busy. Kindly try again"))
					return
				}
				var accumulator []string
				for idx, reg := range regions {
					result := fmt.Sprintf("\n%d. %s", idx+1, reg.Name)
					accumulator = append(accumulator, result)
				}
				jsonData, err := json.MarshalIndent(regions, "", "  ")
				if err != nil {
					fmt.Println("Error marshalling to JSON:", err)
					w.Write([]byte("END System is currently busy. Kindly try again"))
					return
				}
				updates := map[string]interface{}{
					"region_payload": string(jsonData),
				}
				err = services.UpdateUssdSession(updates, session_id)
				if err != nil {
					fmt.Println(err.Error())
					w.Write([]byte("END System is currently busy. Kindly try again"))
					return
				}

				output := strings.Join(accumulator, "")
				fmt.Println(output)
				w.Write([]byte(fmt.Sprintf("CON Choose your Region. %s", output)))
				return
			} else if cnt == 4 && (firstIndexAfterAstk == 1 || firstIndexAfterAstk == 2) && strings.Contains(text, "7") {
				var regions []models.Region
				err := services.GetAllRegion(&regions)
				if err != nil {
					w.Write([]byte("END System is currently busy. Kindly try again"))
					return
				}
				var accumulator []string
				for idx, reg := range regions {
					result := fmt.Sprintf("\n%d. %s", idx+1, reg.Name)
					accumulator = append(accumulator, result)
				}
				jsonData, err := json.MarshalIndent(regions, "", "  ")
				if err != nil {
					fmt.Println("Error marshalling to JSON:", err)
					w.Write([]byte("END System is currently busy. Kindly try again"))
					return
				}
				updates := map[string]interface{}{
					"region_payload": string(jsonData),
				}
				err = services.UpdateUssdSession(updates, session_id)
				if err != nil {
					fmt.Println(err.Error())
					w.Write([]byte("END System is currently busy. Kindly try again"))
					return
				}

				output := strings.Join(accumulator, "")
				fmt.Println(output)
				w.Write([]byte(fmt.Sprintf("CON Choose your Region. %s", output)))
				return
			} else {
				w.Write([]byte("END You have been registered successfully. Thank you."))
				return
			}
		} else {
			w.Write([]byte("END Your request has been received successfully. Thank you."))
		}
	}

}

func getLastValueAfterAsterisk(s string) int {
	if !strings.Contains(s, "*") {
		return -1 // Return the original string if no asterisk is found
	}
	// Split the string by asterisks
	parts := strings.Split(s, "*")

	// Check if there are any parts after splitting
	if len(parts) == 0 {
		return -1
	}

	str := strings.TrimSpace(parts[len(parts)-1])
	num, err := strconv.Atoi(str)
	if err != nil {
		fmt.Println("Error converting string to integer:", err)
		return -1
	}
	// Return the last part (trimmed of any whitespace)
	return num
}

func getfirstValueBeforeAsterisk(s string) int {

	if len(s) == 0 {
		return -1
	}

	if !strings.Contains(s, "*") {
		num, err := strconv.Atoi(s)
		if err != nil {
			fmt.Println("Error converting string to integer:", err)
			return -1
		}
		return num // Return the original string if no asterisk is found
	}
	// Split the string by asterisks
	parts := strings.Split(s, "*")

	// Check if there are any parts after splitting

	str := strings.TrimSpace(parts[0])
	num, err := strconv.Atoi(str)
	if err != nil {
		fmt.Println("Error converting string to integer:", err)
		return -1
	}
	// Return the last part (trimmed of any whitespace)
	return num
}

func getXValueAfterAsterisk(s string) int {

	if len(s) == 0 {
		return -1
	}

	if !strings.Contains(s, "*") {
		num, err := strconv.Atoi(s)
		if err != nil {
			fmt.Println("Error converting string to integer:", err)
			return -1
		}
		return num // Return the original string if no asterisk is found
	}
	// Split the string by asterisks
	parts := strings.Split(s, "*")

	// Check if there are any parts after splitting

	str := strings.TrimSpace(parts[1])
	num, err := strconv.Atoi(str)
	if err != nil {
		fmt.Println("Error converting string to integer:", err)
		return -1
	}
	// Return the last part (trimmed of any whitespace)
	return num
}

func GetRegionByIndex(regions []models.Region, idx int) (models.Region, error) {

	if idx < 0 || idx >= len(regions) {
		return models.Region{}, fmt.Errorf("index out of range")
	}
	return regions[idx], nil
}

func GetCountyByIndex(counties []models.County, idx int) (models.County, error) {

	if idx < 0 || idx >= len(counties) {
		return models.County{}, fmt.Errorf("index out of range")
	}
	return counties[idx], nil
}

func GetConstituencyByIndex(constituencies []models.Constituency, idx int) (models.Constituency, error) {

	if idx < 0 || idx >= len(constituencies) {
		return models.Constituency{}, fmt.Errorf("index out of range")
	}
	return constituencies[idx], nil
}

func GetAreaByIndex(areas []models.Area, idx int) (models.Area, error) {

	if idx < 0 || idx >= len(areas) {
		return models.Area{}, fmt.Errorf("index out of range")
	}
	return areas[idx], nil
}

func GetSubCategoriesByIndex(categories []models.Category, idx int) (models.Category, error) {

	if idx < 0 || idx >= len(categories) {
		return models.Category{}, fmt.Errorf("index out of range")
	}
	return categories[idx], nil
}
