package chaincode

// HTTP STATUS CODES
type HTTP_STATUS_CODE int

const (
	OK               HTTP_STATUS_CODE = 200
	CREATED          HTTP_STATUS_CODE = 201
	BAD_REQUEST      HTTP_STATUS_CODE = 400
	UNAUTHORIZED     HTTP_STATUS_CODE = 401
	FORBIDDEN        HTTP_STATUS_CODE = 403
	NOT_FOUND        HTTP_STATUS_CODE = 404
	METHOD_NOT_ALLOW HTTP_STATUS_CODE = 405
	CONFLICT         HTTP_STATUS_CODE = 409
	INTERNAL_SERVER  HTTP_STATUS_CODE = 500
)

// SUCCESS MESSAGE CONSTANTS
type SUCCESS_MESSAGE string

const (
	SUCCESS SUCCESS_MESSAGE = "success"
)

// ERROR MESSAGE CONSTANTS
type ERROR_MESSAGE string

const (
	POPUP_PRIORITY_ERROR             ERROR_MESSAGE = "Priority should be between 1 to 3"
	NOTICE_ID_UPDATE_ERROR           ERROR_MESSAGE = "Could not update notice id"
	FAQ_ID_UPDATE_ERROR              ERROR_MESSAGE = "Could not update FAQ id"
	SUPPLIER_ID_UPDATE_ERROR         ERROR_MESSAGE = "Could not update Supplier id"
	INPUT_ERROR                      ERROR_MESSAGE = "Please choose Atlest One Service"
	PDF_ERROR                        ERROR_MESSAGE = "Please Upload only PDF Files"
	FILE_ERROR                       ERROR_MESSAGE = "Please Upload Valid Files"
	PRESS_ID_UPDATE_ERROR            ERROR_MESSAGE = "Could not update press id"
	POPUP_ID_UPDATE_ERROR            ERROR_MESSAGE = "Could not update popup id"
	QUESTION_ID_UPDATE_ERROR         ERROR_MESSAGE = "Could not update question id"
	NOTICE_NOT_EXIST                 ERROR_MESSAGE = "Notice does not exist"
	FAQ_NOT_EXIST                    ERROR_MESSAGE = "FAQ does not exist"
	POPUP_NOT_EXIST                  ERROR_MESSAGE = "POP UP does not exist"
	PRESS_NOT_EXIST                  ERROR_MESSAGE = "Press Release does not exist"
	QUESTION_NOT_EXIST               ERROR_MESSAGE = "Question does not exist"
	SUPPLIER_NOT_EXIST               ERROR_MESSAGE = "Supplier does not exist"
	ERROR_UPDATE_QUESTIONID          ERROR_MESSAGE = "ERROR updating Question ID into user record"
	ERROR_UPDATE_NOTICEID            ERROR_MESSAGE = "ERROR updating Notice ID into admin record"
	ERROR_UPDATE_FAQID               ERROR_MESSAGE = "ERROR updating FAQ ID into admin record"
	ERROR_UPDATE_SUPPLIER_ID         ERROR_MESSAGE = "ERROR updating Supplier ID into admin record"
	ERROR_UPDATE_PRESSID             ERROR_MESSAGE = "ERROR updating Press Release ID into admin record"
	ERROR_FETCHING_NOTICE_ID         ERROR_MESSAGE = "Error fetching admin notice ids"
	ERROR_FETCHING_PRESS_ID          ERROR_MESSAGE = "Error fetching admin Press Release ids"
	ALREADY_EXIST                    ERROR_MESSAGE = "Record already exists"
	NOT_EXIST                        ERROR_MESSAGE = "Phone number does not exist / Card information already exist"
	USERNAME_PASSWORD_INCORRECT      ERROR_MESSAGE = "Username or Password is Incorrect"
	CONTACT_PASSWORD_INCORRECT       ERROR_MESSAGE = "Contact or Password is Incorrect"
	INVALID_TOKEN                    ERROR_MESSAGE = "Invalid Token"
	INVALID_INPUT                    ERROR_MESSAGE = "Invalid Input format"
	REQUIRE_TOKEN                    ERROR_MESSAGE = "Required Token"
	REQUIRED_PARAMETERS_MISSING      ERROR_MESSAGE = "REQUIRED API REQUEST PARAMETERS ARE MISSING"
	INTERNAL_SERVER_ERROR            ERROR_MESSAGE = "Internal server error"
	DB_CONNECTION                    ERROR_MESSAGE = "Failed to connect to DB on startup  ERROR_MESSAGE = "
	ID_INSERT_FAIL                   ERROR_MESSAGE = "Error in inserting identity record"
	FETCHING_ID_FAIL                 ERROR_MESSAGE = "Error in fetching identity"
	AMOUNT_DID_TOKEN_CALLER_MISSING  ERROR_MESSAGE = "Amount or ReceiveDID or Token or Caller not Exist!"
	INVALID_URL                      ERROR_MESSAGE = "Invalid URL"
	TRANSACTION_FAILED_AGAINST       ERROR_MESSAGE = "Transaction has been failed against "
	PAYMENT_DONE_MINTING_FAILED      ERROR_MESSAGE = "Payment Done but Minting Token Failed against"
	MINTING_FAILED_TRANSACTIONID     ERROR_MESSAGE = "Minting Failed against TransactionId "
	TRY_MANUALLY                     ERROR_MESSAGE = " Try Manually!"
	ERROR_UPDATE_USERINFO            ERROR_MESSAGE = "ERROR updating User Information!"
	ERROR_UPDATE_LICENSE             ERROR_MESSAGE = "ERROR updating User Driving License!"
	ERROR_UPDATE_TRANSACTION         ERROR_MESSAGE = "ERROR updating Transaction!"
	ERROR_FETCHING_TRANSACTION       ERROR_MESSAGE = "ERROR Fetching Transaction!"
	ERROR_FETCHING_TRANSACTIONS      ERROR_MESSAGE = "ERROR Fetching Transactions!"
	ESCROW_TOKEN_FAILED              ERROR_MESSAGE = "Invalid escrow token"
	SAVE_TRANSACTION_DB_FAILED       ERROR_MESSAGE = "Save Transaction in DB Failed!"
	PG_DB_CONNECTION_ERROR           ERROR_MESSAGE = "PG DB Connection Error!"
	UNABLE_TO_MAKE_CALL              ERROR_MESSAGE = "Unable to make call!"
	UNABLE_TO_MAKE_PAYMENT           ERROR_MESSAGE = "Unable to make payment"
	FAILED_CARD_VERIFICATION         ERROR_MESSAGE = "Failed Card Verification"
	FAILED_FETCHING_PAYMENT_HISTORY  ERROR_MESSAGE = "Failed fetching payment history"
	FAILED_FETCH_BALANCE             ERROR_MESSAGE = "Failed fetch balance"
	FAILED_USER_DID_CREATION         ERROR_MESSAGE = "Failed user DID creation"
	TRANSFER_TOKEN_FAILED            ERROR_MESSAGE = "Transfer token failed"
	LOGIN_MIDDLELAYER_FAILED         ERROR_MESSAGE = "Login_Middlelayer_Failed"
	LOGIN_FAILED                     ERROR_MESSAGE = "User successfully registered on E3DA/MID-DIDwait for sometime"
	LOGINCHECK_FAILED                ERROR_MESSAGE = "Try Again!"
	LOGIN_AGAIN                      ERROR_MESSAGE = "Please login"
	PHONE_NUMBER_NOT_EXIST           ERROR_MESSAGE = "Entered Contact number does not exist"
	ADMIN_ID_NOT_EXIST               ERROR_MESSAGE = "Entered Admin Id does not exist"
	FETCH_CARD_DETAILS               ERROR_MESSAGE = "Failed to fetch card details"
	FETCH_PAYMENT_DETAILS            ERROR_MESSAGE = "Failed to fetch payment hisory details"
	REGISTERING_PAYMENT_CARD         ERROR_MESSAGE = "Failed to register card"
	GET_PAYMENT_CARD                 ERROR_MESSAGE = "Get payment card failed"
	GET_PAYMENT_HISTORY              ERROR_MESSAGE = "Get payment hisory failed"
	DECRYPTION_FAILED                ERROR_MESSAGE = "Failed to decrypt string"
	CHECKING_ADMIN_ERROR             ERROR_MESSAGE = "Admin record does not exists"
	CHECKING_ADMIN_NOTICE_ERROR      ERROR_MESSAGE = "Admin notice record does not exists"
	CHECKING_ADMIN_FAQ_ERROR         ERROR_MESSAGE = "Admin FAQ record does not exists"
	CHECKING_ADMIN_PRESS_ERROR       ERROR_MESSAGE = "Admin Press Release record does not exists"
	FETCHING_ADMIN_ERROR             ERROR_MESSAGE = "Error in admin record fetch"
	FETCHING_OPERATOR_ERROR          ERROR_MESSAGE = "Error in Operator record fetch"
	FETCHING_USER_ERROR              ERROR_MESSAGE = "Error in user record fetch"
	FETCHING_QUESTION_ERROR          ERROR_MESSAGE = "Error in questions record fetch"
	FETCHING_SUPPLIER_NAME_ERROR     ERROR_MESSAGE = "Error in supplier name record fetch"
	FETCHING_SUPPLIER_ERROR          ERROR_MESSAGE = "Error in supplier all record fetch"
	ADMIN_NOT_EXISTS                 ERROR_MESSAGE = "Admin does not exist"
	OPERATOR_NOT_EXISTS              ERROR_MESSAGE = "Operator does not exist"
	MODIFIER_NOT_EXISTS              ERROR_MESSAGE = "Modifier does not exist"
	RESPONDENT_NOT_EXISTS            ERROR_MESSAGE = "Respondent does not exist"
	WRITER_NOT_EXISTS                ERROR_MESSAGE = "Writer does not exist"
	USER_NOT_EXISTS                  ERROR_MESSAGE = "User does not exist"
	WRITER_NAME_NOT_MATCH            ERROR_MESSAGE = "Writer does not match with existing name"
	RESPONDENT_NAME_NOT_MATCH        ERROR_MESSAGE = "Respondent name does not match with existing name"
	ERROR_UPDATE_ADMININFO           ERROR_MESSAGE = "ERROR updating Admin Information!"
	ERROR_UPDATE_OPERATOR_INFO       ERROR_MESSAGE = "ERROR updating Operator Information!"
	ERROR_FETCHING_SUPPLIER_ID       ERROR_MESSAGE = "Error fetching admin supplier ids"
	TOKEN_FAILED                     ERROR_MESSAGE = "Token creation failed"
	ERROR_ADD_QUESTION               ERROR_MESSAGE = "ERROR adding answer for question"
	ERROR_UPDATE_NOTICE              ERROR_MESSAGE = "ERROR in updating notice"
	ERROR_UPDATE_FAQ                 ERROR_MESSAGE = "ERROR in updating FAQ"
	ERROR_UPDATE_PRESS               ERROR_MESSAGE = "ERROR in updating press release"
	FAQID_NOT_EXIST                  ERROR_MESSAGE = "FAQId is not exist"
	TITLE_NOT_EXIST                  ERROR_MESSAGE = "Title is not exist"
	POPUPID_NOT_EXIST                ERROR_MESSAGE = "POPUP ID not exist"
	ID_NOT_EXIST                     ERROR_MESSAGE = "ID is not exist"
	SUPPLIER_ALREADY_EXIST           ERROR_MESSAGE = "Supplier Already exist"
	SUPPLIER_NAME_NOT_EXIST          ERROR_MESSAGE = "Entered supplier name does not exist"
	ERROR_UPDATE_SUPPLIER            ERROR_MESSAGE = "ERROR in updating supplier"
	ERROR_UPDATE_SUPPLIER_SETTLEMENT ERROR_MESSAGE = "ERROR in updating supplier settlement"
	SUPPLIER_EXISTS_ERROR            ERROR_MESSAGE = "Supplier already exist "
	ORDER_NUMBER_NOT_EXIST           ERROR_MESSAGE = "Order Number does not exist"
	TOP_FIX_LIMIT                    ERROR_MESSAGE = "Top fix count limit reached"
	NO_RELEVANT_DATA                 ERROR_MESSAGE = "no relevant data"
	FAILED_SUPPLIER_CREATION         ERROR_MESSAGE = "Failed to create new Supplier"
	FAILED_SUPPLIER_UPDATE           ERROR_MESSAGE = "Failed to update Supplier"
	FAILED_FETCH_SUPPLIER_NAME       ERROR_MESSAGE = "Failed to fetch Supplier Name"
	FAILED_FETCH_SUPPLIER_LIST       ERROR_MESSAGE = "Failed to fetch Supplier List"
	FAILED_FETCH_SUPPLIER_DETAIL     ERROR_MESSAGE = "Failed to fetch Supplier Detail"
	INVALID_PAGE                     ERROR_MESSAGE = "Invalid Page"
	ERROR_UPDATE_SUPPLIER_INFO       ERROR_MESSAGE = "ERROR updating Supplier Information!"
	INVALID_FILE                     ERROR_MESSAGE = "Not a pdf. Only pdf can be uploaded."
	NO_PERMISSION_TO_ACCESS          ERROR_MESSAGE = "YOU HAVE NOT PERMISSION TO ACCESS"
	// 74
	REPORT_NUMBER_NOT_EXIST ERROR_MESSAGE = "Entered Report number does not exist"
	FETCHING_REPORT_ERROR   ERROR_MESSAGE = "Error in report record fetch"
)
