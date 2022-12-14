from turtle import title
from unicodedata import name
from flask import Flask, request, send_file
from werkzeug.exceptions import HTTPException
from datetime import datetime
import os

import users
import utils

app = Flask(__name__)

# -------------- Sample route template -------------------------------------------------------------------------- #
# #
# # description
# #
# @app.route('/--route--', methods=['--method--'])
# def --function--():
#     # get form-data fields
#     email = request.form.get('email')

#     # validate form-data for null values
#     if '' in [email]:
#         return utils.encode_response(status='failure', code=602, desc='invalid user form-data (empty email)')

#     # perform request
#     response = users.get_user(email=email)

#     # return appropriate response
#     if not response:
#         return utils.encode_response(status='failure', code=602, desc='cannot find user')
#     return response
# -------------------------------------------------------------------------------------------------------------- #

#
# default route
#
@app.route('/')
def hello():
    return 'Hello from the Housemates Flask API!'

######################################################### USERS API #################################################################

#
# list all users in db
#
@app.route('/list_users', methods=['GET'])
def get_users():
    response = users.list_users()
    return response

#
# returns profile pic of a specific user
#
@app.route('/profilePic', methods=['GET','POST'])
def get_profile_pic():
    print("BREAK POINT")
    email = request.args.get('email')
    email = email.replace('@', '-')
    email = email.replace('.', '-')
    picFolder = os.path.join('./ProfilePics', email)
    if request.method == 'POST':
        if not os.path.exists(picFolder):
            os.mkdir(picFolder)
        utils.delete_dir_contents(picFolder)
        file = request.files['file']
        img_path = os.path.join(picFolder, file.filename)
        file.save(img_path)
        # return utils.encode_response(status='success', code=200, desc='post image successful')
        return send_file(img_path)
    if os.path.exists(picFolder):
        if len(os.listdir(picFolder))> 0:
            return send_file(os.path.join(picFolder, os.listdir(picFolder)[0]))
    return utils.encode_response(status='failure', code=404, desc='Profile Pic not found')


@app.route('/update_user',methods=['PUT'])
def update_user():
    # validate request json
    signup_fields = ['email', 'first_name', 'last_name', 'password', 'mobile_number']
    valid_json, desc = utils.validate_json_request(signup_fields, request)
    if not valid_json:
        response = utils.encode_response(status='failure', code=602, desc=desc)
        return response

    # build dict from json
    request_dict = request.get_json()

    # get signup fields
    email = request_dict.get('email')
    first_name = request_dict.get('first_name')
    last_name = request_dict.get('last_name')
    password = request_dict.get('password')
    mobile_number = request_dict.get('mobile_number')

    response = users.update_user(email=email, first_name=first_name, last_name=last_name, password=password,
                                 mobile_number=mobile_number)

    return response
#
# account signup
#
@app.route('/signup', methods=['POST'])
def signup():

    # validate request json
    signup_fields = ['email', 'first_name', 'last_name', 'password', 'mobile_number']
    valid_json, desc = utils.validate_json_request(signup_fields, request)
    if not valid_json:
        response = utils.encode_response(status='failure', code=602, desc=desc)
        return response

    # build dict from json
    request_dict = request.get_json()

    # get signup fields
    email = request_dict.get('email')
    first_name = request_dict.get('first_name')
    last_name = request_dict.get('last_name')
    password = request_dict.get('password')
    mobile_number = request_dict.get('mobile_number')

    # perform signup
    response = users.create_user(email=email, first_name=first_name, last_name=last_name, password=password,
                                 mobile_number=mobile_number)
    return response

#
# account login
#
@app.route('/login', methods=['POST'])
def login():

    # validate JSON request
    fields_list = ['email', 'password']
    valid_json, desc = utils.validate_json_request(fields_list, request)
    if not valid_json:
        response = utils.encode_response(status='failure', code=602, desc=desc)
        return response

    # build dict from json
    request_dict = request.get_json()

    # get fields
    email = request_dict.get('email')
    password = request_dict.get('password')

    # perform login
    response = users.get_user(email=email)
    if not response:
        return utils.encode_response(status='failure', code=602, desc='email or password is wrong')

    # check password
    print(response)
    if(password != response['password']):
        return utils.encode_response(status='failure', code=602, desc='email or password is wrong')

    # return users data (included the password!!)
    return utils.encode_response(status='success', code=200, desc='login successful', data=response)

#
# get single user info
#
@app.route('/get_user', methods=['GET'])
def get_user():
    # get params fields
    email = request.args.get('email')

    # validate form-data for null values
    if '' in [email]:
        return utils.encode_response(status='failure', code=602, desc='invalid user form-data (empty email)')

    # perform get user info
    response = users.get_user(email=email)
    if not response:
        return utils.encode_response(status='failure', code=404, desc='user not found')

    # return user data
    # print(response)
    return utils.encode_response(status='success', code=200, desc='get_user successful', data=response)


######################################################### CHORES API #################################################################

#
# add a chore
# due_date should be of type string -- "May 1 2022 10:00AM"

@app.route('/create_chore', methods=['POST'])
def create_chore():
    # validate JSON request
    fields_list = ['desc', 'due_date', 'house_code', 'name', 'assignees']
    valid_json, desc = utils.validate_json_request(fields_list, request)
    if not valid_json:
        response = utils.encode_response(status='failure', code=602, desc=desc)
        return response

    # build dict from json
    request_dict = request.get_json()

    # get fields
    desc = request_dict.get('desc')
    due_date = request_dict.get('due_date')
    house_code = request_dict.get('house_code')
    name = request_dict.get('name')
    assignees = request_dict.get('assignees')

    # perform request
    # NSdate format: "2022-05-31 14:08:48"
    datetime_object = datetime.strptime(due_date, '%Y-%m-%d %H:%M:%S')
    response = users.add_chore(name=name, desc=desc, due_date=datetime_object, house_code=house_code, assignees=assignees)

    # return appropriate response
    return response

#
# description
#
@app.route('/get_chores_by_user', methods=['GET'])
def get_chores_by_user():
    # get params fields
    user_id = request.args.get('user_id')

    # validate form-data for null values
    if '' in [user_id] or (user_id == None):
        return utils.encode_response(status='failure', code=602, desc='invalid user parameters (no id provided)')

    # perform request
    response = users.get_user_chores(user_id=user_id)

    # return appropriate response
    if not response:
        return utils.encode_response(status='failure', code=602, desc='cannot get chores')
    return response


#
# get chores by house code
#
@app.route('/get_chores_by_house_code', methods=['GET'])
def get_chores_by_house_code():
    # get params field
    house_code = request.args.get('house_code')

    # validate params for null values
    if '' in [house_code] or None in [house_code]:
        return utils.encode_response(status='failure', code=602, desc='invalid user parameters (no house code provided)')

    # response request
    response = users.get_house_chores(house_code)
    return response


#
# get chore assignees
#
@app.route('/get_assignees', methods=['GET'])
def get_assignees():
    # get params field
    chore_id = request.args.get('chore_id')

    # validate params for null values
    if '' in [chore_id] or None in [chore_id]:
        return utils.encode_response(status='failure', code=602, desc='invalid user parameters (no chore id provided)')
    # enforce a numeric chore_id
    elif not chore_id.isnumeric():
        return utils.encode_response(status='failure', code=602, desc='invalid user paramters (chore id must be numeric)')

    # response request
    response = users.get_assignees(chore_id)
    return response

#
# get chores and assignees
#
@app.route('/get_chores', methods=['GET'])
def get_chores():
    # get params field
    house_code = request.args.get('house_code')

    # validate params for null values
    if '' in [house_code] or None in [house_code]:
        return utils.encode_response(status='failure', code=602, desc='invalid user parameters (no house code provided)')

    # response request
    response = users.get_chores(house_code)
    return response

#
# edit a chore
#
@app.route('/edit_chore', methods=['PUT'])
def edit_chore():
    # validate JSON request
    chore_fields = ['chore_id', 'name', 'due_date', 'description', 'house_code', 'assignees']
    valid_json, desc = utils.validate_json_request(chore_fields, request)
    if not valid_json:
        response = utils.encode_response(status='failure', code=602, desc=desc)
        return response

    # get dict from json
    request_dict = request.get_json()
    chore_id = request_dict.get('chore_id')
    chore_name = request_dict.get('name')
    due_date = request_dict.get('due_date')
    description = request_dict.get('description')
    assignees = request_dict.get('assignees')
    house_code = request_dict.get('house_code')

    # convert date format
    # due_date = datetime.strptime(due_date, '%B %d %Y %I:%M%p').strftime('%Y-%m-%d %I:%M:%S')

    response = users.edit_chore(chore_id, chore_name, due_date, description, assignees, house_code)
    return response

#
#delete chore
#
@app.route('/delete_chore', methods=['DELETE'])
def delete_chore():
    # validate JSON request
    chore_fields = ['chore_id']
    valid_json, desc = utils.validate_json_request(chore_fields, request)
    if not valid_json:
        response = utils.encode_response(status='failure', code=602, desc=desc)
        return response    # get dict from json

    request_dict = request.get_json()
    chore_id = request_dict.get('chore_id')

    response = users.delete_chore(chore_id)
    return response

#
# assign chore to user in house
#
@app.route('/assign_chore', methods=['POST'])
def assign_chore():
    # validate JSON request
    fields_list = ['user_id', 'chore_id', 'house_code']

    valid_json, desc = utils.validate_json_request(fields_list, request)
    if not valid_json:
        response = utils.encode_response(status='failure', code=602, desc=desc)
        return response

    # build dict from json
    request_dict = request.get_json()

    user_id = request_dict.get('user_id')
    chore_id = request_dict.get('chore_id')
    house_code = request_dict.get('house_code')

    # response request
    response = users.assign_chore(user_id, chore_id, house_code)
    return response

#
# unassign user from chore
#
@app.route('/unassign_chore', methods=['PUT'])
def unassign_chore():
    # validate JSON request
    fields_list = ['user_id', 'chore_id']
    valid_json, desc = utils.validate_json_request(fields_list, request)
    if not valid_json:
        response = utils.encode_response(status='failure', code=602, desc=desc)
        return response

    # build dict from json
    request_dict = request.get_json()

    user_id = request_dict.get('user_id')
    chore_id = request_dict.get('chore_id')

    # response request
    response = users.unassign_chore(user_id, chore_id)
    return response

######################################################### HOUSE/HOUSE RULES API #################################################################

#
# Creates the house rule, #note that voted_num is the # of members
#
@app.route('/create_house_rules', methods=['POST'])
def create_house_rules():

    #get form-data files
    fields_list = ['title', 'description', 'house_code', 'voted_num', "valid"]
    valid_json, desc = utils.validate_json_request(fields_list, request)
    if not valid_json:
        response = utils.encode_response(status='failure', code=602, desc=desc)
        return response
    
    request_dict = request.get_json()

    title = request_dict.get('title')
    description = request_dict.get('description')
    house_code = request_dict.get('house_code')
    voted_num = request_dict.get('voted_num')
    valid = request_dict.get('valid')

    # validate that title-data has no null values
    if '' in [title]:
        return utils.encode_response(status='failure', code=602, desc='invalid user form-data (empty house rule)')

    # # validate that housecode-data has no null values
    if '' in [house_code]:
        return utils.encode_response(status='failure', code=602, desc='invalid user form-data (empty housecode)')

    # # validate that vote-data has no null values
    if '' in [voted_num]:
        return utils.encode_response(status='failure', code=602, desc='invalid user form-data (empty voters)')
    # get all the form-data value and check if its present
    response = users.add_house_rules(title=title, description=description, house_code=house_code, voted_num=voted_num,valid=valid)
    if not response:
        return utils.encode_response(status='failure', code=404, desc='house_rules not found')

    #return the form-data values
    return response

#
# get house rules
#
@app.route('/get_house_rules', methods=['GET'])
def get_house_rules():
    # get params field
    house_code = request.args.get('house_code')

    # validate params for null values
    if '' in [house_code] or None in [house_code]:
        return utils.encode_response(status='failure', code=602, desc='invalid user parameters (no house code provided)')

    # response request
    response = users.get_house_rules(house_code)
    return response

#
#delete house rule
#
@app.route('/delete_house_rule', methods=['DELETE'])
def delete_house_rule():
    # validate JSON request
    chore_fields = ['house_rule_id']
    valid_json, desc = utils.validate_json_request(chore_fields, request)
    if not valid_json:
        response = utils.encode_response(status='failure', code=602, desc=desc)
        return response    # get dict from json

    request_dict = request.get_json()
    house_rule_id = request_dict.get('house_rule_id')

    response = users.delete_house_rule(house_rule_id)
    return response

#
# sample json post request
#
@app.route('/post_json', methods=['POST'])
def process_json():

    # validate JSON request
    fields_list = ['field1', 'field2', 'field3']
    valid_json, desc = utils.validate_json_request(fields_list, request)
    if not valid_json:
        response = utils.encode_response(status='failure', code=602, desc=desc)
        return response

    # at this point the JSON is valid...

    # request_dict holds all field,value pairs
    request_dict = request.get_json()
    print("Request Dict: ", request_dict)

    # extract values from fields
    field1 = request_dict.get('field1')
    field2 = request_dict.get('field2')
    field3 = request_dict.get('field3')
    print("Field values: ", field1, field2, field3)

    response = utils.encode_response(status='success', code=200, desc="successful json post", data=request_dict)
    return response

#
# join house given an user_id and valid house code
#
@app.route('/join_house', methods=['POST'])
def join_house():
    # validate JSON request
    fields_list = ['user_id', 'house_code']
    valid_json, desc = utils.validate_json_request(fields_list, request)
    if not valid_json:
        response = utils.encode_response(status='failure', code=602, desc=desc)
        return response

    # build dict from json
    request_dict = request.get_json()

    # get fields
    user_id = request_dict.get('user_id')
    house_code = request_dict.get('house_code')

    # perform request
    response = users.join_house(house_code=house_code, user_id=user_id)

    # return appropriate response
    return response

#
# leave house given an user_id
#
@app.route('/leave_house', methods=['POST'])
def leave_house():
    # validate JSON request
    fields_list = ['user_id']
    valid_json, desc = utils.validate_json_request(fields_list, request)
    if not valid_json:
        response = utils.encode_response(status='failure', code=602, desc=desc)
        return response

    # build dict from json
    request_dict = request.get_json()

    # get fields
    user_id = request_dict.get('user_id')

    # perform request
    response = users.leave_house(user_id=user_id)

    # return appropriate response
    return response

@app.route('/get_house_members', methods=['GET'])
def get_house_memebers():
    # Gets the house code with ?house_code=*HOUSE CODE*
    house_code = request.args.get('house_code')

    # validate params for null values
    if '' in [house_code] or None in [house_code]:
        return utils.encode_response(status='failure', code=602, desc='invalid user parameters (no house code provided)')

    # response request
    response = users.get_house_members(house_code)
    return response

#
#Creates New House
#
@app.route('/create_house', methods=['POST'])
def create_house():
    # if New_House_code is in
    fields_list = ['user_id']
    valid_json, desc = utils.validate_json_request(fields_list, request)
    if not valid_json:
        response = utils.encode_response(status='failure', code=602, desc=desc)
        return response
    # build dict from json
    request_dict = request.get_json()

    # get fields
    user_id = request_dict.get('user_id')

    # perform request
    response = users.create_house(user_id=user_id)

    # return appropriate response
    return response



#
# edit house rules
#
@app.route('/edit_house_rules', methods=['PUT'])
def edit_house_rules():
    # validate JSON request
    house_rules_list = ['title', 'description', 'rule_id']
    valid_json, desc = utils.validate_json_request(house_rules_list, request)
    if not valid_json:
        response = utils.encode_response(status='failure', code=602, desc=desc)
        return response

    # build dict from json
    request_dict = request.get_json()

    rule_id = request_dict.get('rule_id')
    rule_title = request_dict.get('title')
    rule_description = request_dict.get('description')

    # response request
    response = users.edit_house_rules(rule_id, rule_title, rule_description)
    return response

#
# Return only approved house rules associated by given house_code
#
@app.route('/get_approved_house_rules', methods=['GET'])
def get_approved_house_rules():
    # get form-data fields
    house_code = request.args.get('house_code')

    # validate form-data for null values
    if '' in [house_code] or None in [house_code]:
        return utils.encode_response(status='failure', code=602, desc='invalid request (empty house code)')

    # perform request
    response = users.get_approved_house_rules(house_code=house_code)

    # return appropriate response
    if not response:
        return utils.encode_response(status='failure', code=602, desc='cannot find user')
    return response

#
# Return only UNapproved house rules associated by given house_code
#
@app.route('/get_not_approved_house_rules', methods=['GET'])
def get_not_approved_house_rules():
    # get form-data fields
    house_code = request.args.get('house_code')

    # validate form-data for null values
    if '' in [house_code] or None in [house_code]:
        return utils.encode_response(status='failure', code=602, desc='invalid request (empty house code)')

    # perform request
    response = users.get_not_approved_house_rules(house_code=house_code)

    # return appropriate response
    if not response:
        return utils.encode_response(status='failure', code=602, desc='cannot find user')
    return response

@app.route('/get_unvoted_house_rules', methods=['GET'])
def get_unvoted_house_rules():

    # get form-data fields
    house_code = request.args.get('house_code')
    user_id = request.args.get('user_id')
    
    # validate form-data for null values
    if '' in [house_code] or None in [house_code]:
        return utils.encode_response(status='failure', code=602, desc='invalid request (empty house code)')

    if '' in [user_id] or None in [user_id]:
        return utils.encode_response(status='failure', code=602, desc='invalid request (empty user_id)')

    #perform request
    response = users.get_unvoted_house_rules_assignees(house_code=house_code, user_id=user_id)

    # return appropriate response
    if not response:
        return utils.encode_response(status='failure', code=602, desc='cannot find user')
    return response

#
#updates the voted_num field in the house_rules table
#
@app.route('/update_house_rule_voted_num', methods=['PUT'])
def vote_house_rule():
    # validate request json
    signup_fields = ['user_id', 'rule_id', 'update_value']
    valid_json, desc = utils.validate_json_request(signup_fields, request)
    if not valid_json:
        response = utils.encode_response(status='failure', code=602, desc=desc)
        return response

    # build dict from json
    request_dict = request.get_json()

    # get signup fields
    user_id = request_dict.get('user_id')
    rule_id = request_dict.get('rule_id')
    update_value = request_dict.get('update_value')

    response = users.vote_house_rule(user_id, rule_id, update_value)
    return response


#
# Handle HTTP and application errors
#
@app.errorhandler(Exception)
def handle_exception(e):
    print(e)

    # pass through HTTP errors
    if isinstance(e, HTTPException):
        return e

    # now you're handling non-HTTP exceptions only
    exception_str = str(e)
    response = utils.encode_response(status='failure', code=500, desc=exception_str)
    return response


#
# app.py entry point
#
if __name__ == "__main__":
    # run app on localhost:8080
    app.run(host='127.0.0.1', port=8080, debug=True)


