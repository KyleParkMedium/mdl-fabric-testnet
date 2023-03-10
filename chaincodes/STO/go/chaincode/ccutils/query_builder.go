package ccutils

import (
	"encoding/json"
	"fmt"
)

type Query struct {
	Selector map[string]interface{} `json:"selector,omitempty"`
	UseIndex []interface{}          `json:"use_index,omitempty"`
	Sort     []map[string]string    `json:"sort,omitempty"`
	// Fields   []interface{}          `json:"fields,omitempty"`

	// Limit    int `json:"limit,omitempty"`
	// Skip     int `json:"skip,omitempty"`
	// Bookmark string

}

func (q *Query) AddSelector(selector map[string]interface{}) error {
	if q.Selector == nil {
		q.Selector = make(map[string]interface{})
	}

	q.Selector = selector

	return nil
}

// func (q *Query) AddFields(fields []interface{}) error {
// 	if q.Fields == nil {
// 		q.Fields = make([]interface{}, 0)
// 	}

// 	q.Fields = append(q.Fields, fields)

// 	return nil
// }

func (q *Query) AddIndex(index []interface{}) error {
	if q.UseIndex == nil {
		q.UseIndex = make([]interface{}, 0)
	}

	q.UseIndex = index

	// q.UseIndex = append(q.UseIndex, index)

	return nil
}

func (q *Query) AddSort(sort map[string]string) error {
	if q.Sort == nil {
		q.Sort = make([]map[string]string, 0)
	}

	q.Sort = append(q.Sort, sort)

	return nil
}

func (q *Query) MakeQueryString() (string, error) {
	query := make(map[string]interface{})

	query["selector"] = q.Selector
	// if len(q.Fields) != 0 {
	// 	query["fields"] = q.Fields
	// }
	if len(q.UseIndex) != 0 {
		query["use_index"] = q.UseIndex
	}
	if len(q.Sort) != 0 {
		query["sort"] = q.Sort
	}

	fmt.Println(q)
	bytes, err := json.Marshal(query)
	if err != nil {
		return "", err
	}

	return string(bytes), nil
}

type QueryBuilder struct {
	selector map[string]interface{}
	sort     map[string]interface{}
	// sort     []map[string]string
	field []interface{}
}

func (q *QueryBuilder) AddSelectorKey(field string) *QueryBuilder {
	if q.selector == nil {
		q.selector = make(map[string]interface{})
	}

	// myMap := make(map[string]map[string]bool)

	// innerMap := make(map[string]bool)
	// innerMap["$exists"] = true

	// myMap[imsy] = innerMap

	// q.selector = map[string]interface{}{
	// 	field: myMap,
	// }

	q.selector = map[string]interface{}{
		field: map[string]bool{
			"$exists": true,
		},
	}

	fmt.Println(field)
	fmt.Println(q)

	return q
}

func (q *QueryBuilder) AddSelectorGroup(field string, value interface{}) *QueryBuilder {
	if q.selector == nil {
		q.selector = make(map[string]interface{})
	}

	q.selector[field] = value

	fmt.Println(q)
	return q
}

func (q *QueryBuilder) AddSelectorGroupCondition(field string, condition string, value interface{}) *QueryBuilder {
	if q.selector == nil {
		q.selector = make(map[string]interface{})
	}

	if q.selector[field] == nil {
		q.selector[field] = make(map[string]interface{})
	}
	q.selector[field].(map[string]interface{})[condition] = value

	return q
}

func (q *QueryBuilder) AddSelectorArrayGroupCondition(field string, condition1 string, value1 interface{}) *QueryBuilder {
	if q.selector == nil {
		q.selector = make(map[string]interface{})
	}

	if q.selector[field] == nil {
		q.selector[field] = make([]map[string]interface{}, 0)
	}

	element := make(map[string]interface{})
	element[condition1] = value1
	//element[condition2] = value2

	arrayGroup := q.selector[field].([]map[string]interface{})
	arrayGroup = append(arrayGroup, element)
	q.selector[field] = arrayGroup

	return q
}

func (q *QueryBuilder) AddSortField(field string, orderBy interface{}) *QueryBuilder {
	if q.sort == nil {
		q.sort = make(map[string]interface{})
	}

	q.sort[field] = orderBy

	// sortItem := make(map[string]interface{})
	// sortItem[field] = orderBy
	// q.sort = append(q.sort, sortItem)

	return q
}

func (q *QueryBuilder) MakeQueryString() string {
	query := make(map[string]interface{})

	if len(q.selector) != 0 {
		query["selector"] = q.selector
	}

	// if len(q.sort) != 0 {
	// 	query["sort"] = q.sort
	// }

	if len(q.field) != 0 {
		query["fields"] = q.field
	}

	bytes, err := json.Marshal(query)
	if err != nil {
		return ""
	}

	return string(bytes)
}

func (q *QueryBuilder) AddFieldGroup(key string) *QueryBuilder {
	if q.field == nil {
		q.field = make([]interface{}, 0)
	}
	q.field = append(q.field, key)

	return q
}
