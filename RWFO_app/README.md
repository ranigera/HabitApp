## This is the Space Gold app code (frontend code).
### Notes:
* The task is comprehensivly described in the paper - A novel smartphone app for experimental habit induction in humans (Gera et al.)
* The app is designed as a progressive web application (PWA) and is compatible with both iphones and andorid-based smartphones.
* It is designed to be connected with a mongoDB database and to use websockets for fast communication.

### To use it: 
* Look for the place holder ROOT_DOMAIN in settings.js and create_subject_keycodes.py and insert the root domain used.
* First run create_subject_keycodes_and_manifests.py to create subject ID codes, links and related files.
* It needs to be associated with a backend code and a mogoDB database (or adjust to use other alternative).

