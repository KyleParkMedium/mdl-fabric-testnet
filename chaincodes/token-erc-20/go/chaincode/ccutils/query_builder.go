package ccutils

import "encoding/json"

type QueryBuilder struct {
	selector map[string]interface{}
	sort     []map[string]string
}

func (q *QueryBuilder) AddSelectorGroup(field string, value interface{}) *QueryBuilder {
	if q.selector == nil {
		q.selector = make(map[string]interface{})
	}

	q.selector[field] = value

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

func (q *QueryBuilder) AddSortField(field string, orderBy string) *QueryBuilder {
	if q.sort == nil {
		q.sort = make([]map[string]string, 0)
	}

	sortItem := make(map[string]string)
	sortItem[field] = orderBy
	q.sort = append(q.sort, sortItem)

	return q
}

func (q *QueryBuilder) MakeQueryString() string {
	query := make(map[string]interface{})

	query["selector"] = q.selector
	if len(q.sort) != 0 {
		query["sort"] = q.sort
	}

	bytes, err := json.Marshal(query)
	if err != nil {
		return ""
	}

	return string(bytes)
}
