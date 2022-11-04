# Created by Rani Gera
# *** Don't use this one - use create_subject_keycodes_and_manifests.py ***
# *** This one is to be used only if one wants to adjust the code and not use individual manifest files ***

import os
from shutil import copyfile
import csv
import json
import time
import string
import random


# FUNCTIONS:

def get_random_string(length):
    letters = string.ascii_letters + string.digits
    result_str = ''.join(random.choice(letters) for i in range(length))
    return result_str


def createSubNumDict(ranges=[(101, 200), (201, 300), (701, 800), (801, 900)], key_code_length=20):
    sub_key_dict = {}
    for i in ranges:
        for j in range(i[0], i[1]):
            # the logic here below is to prevent the last 3 characters of being the same.
            get_code = True
            while get_code:
                new_key = get_random_string(key_code_length)
                get_code = False
                for key in sub_key_dict.keys():
                    if new_key[-3:].lower() == key[-3:].lower():
                        get_code = True
                        break

            sub_key_dict[new_key] = j

    return sub_key_dict


# RUN THE CODE:
sub_key_dict = createSubNumDict()

if not os.path.exists('./mapping_key_to_subId.js'):
    # create the js file:
    with open('mapping_key_to_subId.js', 'w') as f:
        f.write('var key2subId_mapping = ')
        json.dump(sub_key_dict, f, indent=4)
    print('The file mapping_key_to_subId.js was saved')
    # backup a copy with a timestamp:
    copyfile('mapping_key_to_subId.js',
             'backup/mapping_key_to_subId' + str(time.time()) + '.js')

    # saving a csv file with url's:
    with open('mapping_key_to_subId.csv', 'w', newline='') as file:
        writer = csv.writer(file)
        writer.writerow(["Sub_ID", "URL", "key_code"])
        for key, val in sub_key_dict.items():
            writer.writerow(
                [val, 'https://ROOT_DOMAIN/static/rani/Space_Gold_App7/index.html?subId=' + key, key])
    print('The file mapping_key_to_subId.csv was saved')
    # backup a copy with a timestamp:
    copyfile('mapping_key_to_subId.csv',
             'backup/mapping_key_to_subId.' + str(time.time()) + '.csv')
else:
    print('STOPPING! *** The files already exists ***')
